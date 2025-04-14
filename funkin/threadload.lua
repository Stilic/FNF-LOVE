-- singleton

local tasks = love.thread.getChannel("tasks")
local results = love.thread.getChannel("results")
local threads = {}

local ThreadLoad = {
	queue = {},
	completed = 0,
	onComplete = nil,
	running = false
}

local threadCode = [[
	require "love.image"
	require "love.sound"
	require "love.audio"
	require "love.timer"

	local tasks = love.thread.getChannel("tasks")
	local results = love.thread.getChannel("results")

	local function loadFile(type, path)
		local success, data
		if type == "image" then
			success, data = pcall(love.image.newImageData, path)
			if not success then
				data = love.image.newImageData(1, 1)
			end
		elseif type == "sound" then
			success, data = pcall(love.sound.newSoundData, path)
		elseif type == "audio" then
			success, data = pcall(love.audio.newSource, path, "stream")
		end
		return data, success
	end

	while true do
		local task = tasks:pop()
		if task == "exit" then break end
		if task then
			local type, path = task[1], task[2]
			local data, success = loadFile(type, path)
			results:push({type, path, data, success})
		else
			love.timer.sleep(0.001)
		end
	end
]]

function ThreadLoad.getFullPath(type, path)
	if type == "image" then
		return paths.getPath("images/" .. path .. ".png")
	elseif type == "sound" then
		return paths.getPath("sounds/" .. path .. ".ogg")
	else
		return path
	end
end

function ThreadLoad.add(files)
	local existingPaths = {}
	for _, file in ipairs(ThreadLoad.queue) do
		existingPaths[file[1] .. file[2]] = true
	end

	for _, file in ipairs(files) do
		local fileType, path = file[1], file[2]
		if path ~= nil then
			local fullPath = ThreadLoad.getFullPath(fileType, path)
			if not paths.exists(fullPath) then
				print(path .. " doesnt exists, ignoring.")
			else
				if not paths.images[fullPath] and not paths.audio[fullPath] and not existingPaths[fileType .. path] then
					table.insert(ThreadLoad.queue, file)
					existingPaths[fileType .. path] = true
				end
			end
		end
	end
end

function ThreadLoad.start(onComplete)
	if ThreadLoad.running then return end

	ThreadLoad.running = true
	ThreadLoad.completed = 0
	ThreadLoad.onComplete = onComplete

	if #ThreadLoad.queue == 0 then return ThreadLoad.finish() end

	for i = 1, love.system.getProcessorCount() - 1 do
		local thread = love.thread.newThread(threadCode)
		table.insert(threads, thread)
		thread:start()
	end

	for _, task in ipairs(ThreadLoad.queue) do
		local type, path = task[1], task[2]
		local full = ThreadLoad.getFullPath(type, path)
		tasks:push({type, full})
	end
end

function ThreadLoad.update()
	if not ThreadLoad.running then return end

	while results:getCount() > 0 do
		local result = results:pop()
		ThreadLoad.completed = ThreadLoad.completed + 1

		if not result[4] then
			print("Failed to load " .. result[2] .. " (not enough RAM or corrupt)")
		end
		if result[1] == "image" then
			local image = love.graphics.newImage(result[3])
			paths.images[result[2]] = image
		elseif result[1] == "sound" or result[1] == "audio" then
			paths.audio[result[2]] = result[3]
		end
	end

	if ThreadLoad.isFinished() then ThreadLoad.finish() end
end

function ThreadLoad.getProgress()
	if #ThreadLoad.queue == 0 then return 1 end
	return ThreadLoad.completed / #ThreadLoad.queue
end

function ThreadLoad.isFinished()
	return ThreadLoad.completed >= #ThreadLoad.queue
end

function ThreadLoad.finish()
	for _, thread in ipairs(threads) do
		tasks:push("exit")
		thread:release()
	end

	if ThreadLoad.onComplete then
		ThreadLoad.onComplete()
	end

	table.clear(threads)

	table.clear(ThreadLoad.queue)
	ThreadLoad.onComplete = nil
	ThreadLoad.completed = 0
	ThreadLoad.running = false
end

return ThreadLoad
