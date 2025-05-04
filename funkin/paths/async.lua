local async = {debug = true}

local max = math.min(1, love.system.getProcessorCount() - 2)
local threads = {}
local c_task = love.thread.getChannel("async_tasks")
local c_results = love.thread.getChannel("async_results")

local pending = {tasks = {}, callbacks = {}}
local stats = {0, 0, false}
local timer = {time = 0, timeout = 5}

local threadCode = [[
	require "love.image"; require "love.sound"; require "love.audio"
	local s, Https = pcall(require, "https")
	if not s then Https = require "lib.https" end

	local function startsWith(string, prefix) return string.find(string, prefix, 1, true) == 1 end

	local c_task = love.thread.getChannel("async_tasks")
	local c_results = love.thread.getChannel("async_results")

	local function load(type, path, id)
		local success, data
		if type == "image" then
			if startsWith(path, "http://") or startsWith(path, "https://") then
				success, data = pcall(function()
					local code, response = Https.request(path)
					if code ~= 200 then
						error("Failed to fetch image: HTTP " .. tostring(code))
					end
					local fileData = love.filesystem.newFileData(response, ".png")
					local imgData = love.image.newImageData(fileData)
					fileData:release()
					return imgData
				end)
			else
				success, data = pcall(love.image.newImageData, path)
			end
		elseif type == "sound" then
			success, data = pcall(love.sound.newSoundData, path)
		elseif type == "audio" then
			success, data = pcall(love.audio.newSource, path, "stream")
		end
		if not success then
			return {false, tostring(data or ("missing type: " .. type)), id, type, path}
		end
		return {true, data, id, type, path}
	end

	local running = true
	while running do
		local task = c_task:demand()
		if task == "exit" then running = false; break end
		local type, task, id = unpack(task)
		if task then c_results:push(load(type, task, id)) end
	end
]]

local function createThread()
	if #threads >= max then return false end
	return true
end

function async.initialize()
	if stats[3] then return end
	stats[3], timer.time = true, 0

	local thread
	for i = 1, max do
		thread = love.thread.newThread(threadCode)
		table.insert(threads, thread)
		thread:start()
	end
end

function async.processQueue()
	async.initialize()

	while #pending.tasks > 0 do
		local task = table.remove(pending.tasks, 1)
		c_task:push(task)
	end
end

function async.update(dt)
	while true do
		local result = c_results:pop()
		if not result then break end
		stats[2] = stats[2] + 1

		local success, data, id, type, path = unpack(result)
		local dispatch, err
		if success then
			if type == "image" then
				local image = love.graphics.newImage(data)
				local cachePath = path
				if path:startsWith("http://") or path:startsWith("https://") then
					cachePath = "online:" .. path
					err = path
				end
				paths.images[cachePath] = image
				data:release()
				dispatch = image
			elseif type == "sound" or type == "audio" then
				paths.audio[path] = data
				dispatch = data
			end
		else
			if async.debug then print("async loading failed for " .. path .. ": " .. data) end
			dispatch, err = nil, data
		end

		local callbacks = pending.callbacks[id]
		if callbacks then
			for _, callback in pairs(callbacks) do
				callback(dispatch, err)
			end
		end
		pending.callbacks[id] = nil
	end

	if stats[3] then
		if stats[2] >= #pending.tasks then
			timer.time = timer.time + dt
			if timer.time >= timer.timeout then
				async.shutdown()
			end
		else
			timer.time = 0
			async.processQueue()
		end
	end
end

function async.queueTask(type, path, callback)
	local id = type .. ":" .. path
	local task = {type, path, id}

	if callback then
		if not pending.callbacks[id] then
			pending.callbacks[id] = {}
		end
		table.insert(pending.callbacks[id], callback)
	end

	table.insert(pending.tasks, task)
	stats[1] = stats[1] + 1

	async.processQueue()
	return id
end

function async.getImage(key, callback)
	if key:startsWith("http://") or key:startsWith("https://") then
		local path = key
		local obj = paths.images["online:" .. path]
		if obj then
			if callback then callback(obj, key) end
			return obj
		end
		async.queueTask("image", path, callback)
		return true
	else
		local path = paths.getPath("images/" .. key .. ".png")
		local obj = paths.images[path]
		if obj then
			if callback then callback(obj) end
			return obj
		end

		if paths.exists(path, "file") then
			async.queueTask("image", path, callback)
			return true
		else
			if async.debug then print('image not found: ' .. key) end
			if callback then callback(nil) end
		end
	end

	return nil
end

function async.getAudio(key, stream, callback)
	local path = paths.getPath(key .. ".ogg")
	local obj = paths.audio[path]
	if obj then
		if callback then callback(obj) end
		return obj
	end

	if paths.exists(path, "file") then
		async.queueTask(stream and "audio" or "sound", path, callback)
		return true
	else
		if async.debug then print('audio not found: ' .. key) end
		if callback then callback(nil) end
	end
	return nil
end

function async.getMusic(key, callback)
	return async.getAudio("music/" .. key, true, callback)
end

function async.getSound(key, callback)
	return async.getAudio("sounds/" .. key, false, callback)
end

function async.getInst(song, suffix, callback)
	return async.getAudio("songs/" .. paths.formatToSongPath(song) .. "/Inst" ..
		(suffix and "-" .. suffix or ""), true, callback)
end

function async.getVoices(song, suffix, callback)
	return async.getAudio("songs/" .. paths.formatToSongPath(song) .. "/Voices" ..
		(suffix and "-" .. suffix or ""), true, callback)
end

local function loadAtlas(key, kind, callback)
	local imgPath = paths.getPath("images/" .. key .. ".png")
	local dataPath = paths.getPath("images/" .. key .. (
		kind == "sparrow" and ".xml" or ".txt"))

	local cachekey = paths.getPath("images/" .. key)
	local obj = paths.atlases[cachekey]

	if obj then if callback then callback(obj) end; return obj end

	if not paths.exists(dataPath, "file") then
		local type = kind == "sparrow" and "XML" or "TXT"
		if async.debug then print(type .. ' file not found for atlas: ' .. key) end
		if callback then callback(nil) end
		return nil
	end

	local function processAtlas(img)
		if not img then if callback then callback(nil) end; return nil end
		local data = love.filesystem.read(dataPath)
		if not data then
			local type = kind == "sparrow" and "XML" or "TXT"
			if async.debug then print('failed to read ' .. type .. ' file: ' .. dataPath) end
			if callback then callback(nil) end
			return nil
		end
		local name = "from" .. kind:capitalize()
		obj = FrameCollection[name](img, data)
		paths.atlases[cachekey] = obj
		if callback then callback(obj) end; return obj
	end

	local img = paths.images[imgPath]
	if img then
		return processAtlas(img)
	else
		async.getImage(key, processAtlas)
		return true
	end
end

function async.getSparrowAtlas(key, callback)
	return loadAtlas(key, "sparrow", callback)
end

function async.getPackerAtlas(key, callback)
	return loadAtlas(key, "packer", callback)
end

function async.getAtlas(key, callback)
	if paths.exists(paths.getPath("images/" .. key .. ".xml"), "file") then
		return async.getSparrowAtlas(key, callback)
	end
	return async.getPackerAtlas(key, callback)
end

function async.loadBatch(files, onComplete)
	local callback = function()
		local full = (stats[1] == 0) or (stats[2] / stats[1]) == 1
		if full and onComplete then
			onComplete()
		end
	end

	for _, file in ipairs(files) do
		local type, path, suffix = unpack(file)
		switch(type, {
			["image"]  = function() async.getImage(path, callback) end,
			["atlas"]  = function() async.getAtlas(path, callback) end,
			["sound"]  = function() async.getSound(path, callback) end,
			["audio"]  = function() async.getAudio(path, true, callback) end,
			["inst"]   = function() async.getInst(path, suffix, callback) end,
			["voices"] = function() async.getVoices(path, suffix, callback) end,
		})
	end
end

function async.shutdown()
	if not stats[3] then return end

	for _, thread in pairs(threads) do
		if type(thread) ~= "number" then
			c_task:push("exit")
			thread:release()
		end
	end

	table.clear(threads)
	table.clear(pending.tasks)
	table.clear(pending.callbacks)

	stats = {0, 0, false}
	timer.time = 0
end

function async.getProgress()
	if stats[1] == 0 then return 1 end
	return stats[2] / stats[1]
end

return async
