local wave = require "lib.wave"
local decodeJson = (require "lib.json").decode

local function isFile(path)
	local info = love.filesystem.getInfo(path)
	return info and info.type == "file"
end

local function readFile(key)
	if isFile(key) then return love.filesystem.read(key) end
	return nil
end

local paths = {
	images = {},
	audio = {},
	atlases = {},
	fonts = {},
	persistantAssets = { "music/freakyMenu.ogg" }
}

function paths.isPersistant(path)
	for _, k in ipairs(paths.persistantAssets) do
		if path:startsWith(k) then return true end
	end
	return false
end

function paths.clearCache()
	for k, o in pairs(paths.images) do
		if not paths.isPersistant(k) then
			o:release()
			paths.images[k] = nil
		end
	end
	for k, o in pairs(paths.audio) do
		if not paths.isPersistant(k) then
			o:stop()
			paths.audio[k] = nil
		end
	end
	for k, o in pairs(paths.atlases) do
		if not paths.isPersistant(k) then
			o.texture:release()
			for _, f in pairs(o.frames) do f.quad:release() end
			paths.atlases[k] = nil
		end
	end
	for k, o in pairs(paths.fonts) do
		if not paths.isPersistant(k) then
			o:release()
			paths.fonts[k] = nil
		end
	end
	collectgarbage()
end

function paths.getPath(key) return "assets/" .. key end

function paths.getText(key) return readFile(paths.getPath("data/" .. key .. ".txt")) end

function paths.getJSON(key) return decodeJson(readFile(paths.getPath(key .. ".json"))) end

function paths.getFont(key, size, cache)
	if size == nil then size = 12 end
	if cache == nil then cache = true end

	local path = paths.getPath("fonts/" .. key)
	key = path .. "_" .. size
	if cache then
		local obj = paths.fonts[key]
		if obj then
			return obj
		end
	end
	if isFile(path) then
		local obj = love.graphics.newFont(path, size)
		if cache then
			paths.fonts[key] = obj
		end
		return obj
	end

	print('oh no its returning "font" null NOOOO: ' .. path)
	return nil
end

function paths.getImage(key, cache)
	if cache == nil then cache = true end

	key = paths.getPath("images/" .. key .. ".png")
	if cache then
		local obj = paths.images[key]
		if obj then
			return obj
		end
	end
	if isFile(key) then
		local obj = love.graphics.newImage(key)
		if cache then
			paths.images[key] = obj
		end
		return obj
	end

	print('oh no its returning "image" null NOOOO: ' .. key)
	return nil
end

function paths.getAudio(key, type, cache)
	if cache == nil then cache = true end

	key = paths.getPath(key .. ".ogg")
	if cache then
		local obj = paths.audio[key]
		if obj then
			return obj
		end
	end
	if isFile(key) then
		local obj = wave:newSource(key, type)
		if cache then
			paths.audio[key] = obj
		end
		return obj
	end

	print('oh no its returning "audio" null NOOOO: ' .. key)
	return nil
end

function paths.getMusic(key, cache)
	return paths.getAudio("music/" .. key, "stream", cache)
end

function paths.getSound(key, cache)
	return paths.getAudio("sounds/" .. key, "static", cache)
end

function paths.playSound(key, cache)
	local sound = paths.getSound(key, cache)
	if sound then sound:play() end
	return sound
end

function paths.getSparrowAtlas(key, cache)
	if cache == nil then cache = true end

	local imgPath, xmlPath = key, paths.getPath("images/" .. key .. ".xml")
	key = paths.getPath("images/" .. key)
	if cache then
		local obj = paths.atlases[key]
		if obj then
			return obj
		end
	end
	local img = paths.getImage(imgPath, cache)
	if img and isFile(xmlPath) then
		local obj = Sprite.getFramesFromSparrow(img, readFile(xmlPath))
		if cache then
			paths.atlases[key] = obj
		end
		return obj
	end

	return nil
end

function paths.getLua(key)
	local path = paths.getPath(key .. ".lua")
	if isFile(path) then
		local chunk = love.filesystem.load(path)
		return chunk
	end
	return nil
end

return paths
