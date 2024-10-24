local json = require("lib.json")

local Save = {
	data = {},
	path = '',
	initialized = false
}

function Save.init(name)
	if Save.initialized then return end
	Save.initialized = true

	if love.system.getDevice() == "Mobile" then
		Save.path = love.filesystem.getSaveDirectory()
		local dataFile = love.filesystem.read(name .. '.lox')
		if dataFile then
			local decodeData = love.data.decode("string", "hex", dataFile)
			Save.data = json.decode(decodeData)
		end
	else
		Save.path = love.filesystem.getAppdataDirectory() .. '/' .. Project.company .. '/' .. Project.file
		local filePath = Save.path .. '/' .. name .. '.lox'
		local dataFile = io.open(filePath, "rb")
		if dataFile then
			local decodeData = love.data.decode("string", "hex", dataFile:read("a"))
			Save.data = json.decode(decodeData)
			dataFile:close()
		end
	end
end

function Save.bind(name)
	local encodeData = love.data.encode("string", "hex", json.encode(Save.data))
	if love.system.getDevice() == "Mobile" then
		love.filesystem.write(name .. '.lox', encodeData)
	else
		local filePath = Save.path .. '/' .. name .. '.lox'
		local dirCheck = io.open(filePath, "wb")
		if not dirCheck then
			local dirToMake = filePath:gsub('/' .. name .. '.lox', '')
			if love.system.getOS() == "Windows" then
				os.execute('mkdir "' .. dirToMake .. '"')
			else
				os.execute('mkdir -p "' .. dirToMake .. '"')
			end
		end
		local saveFile = io.open(filePath, "wb")
		saveFile:write(encodeData)
		saveFile:close()
	end
end

return Save
