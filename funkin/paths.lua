local decodeJson = (require "lib.json").decode
local nativefs = require "lib.nativefs"

local function readFile(key)
	if paths.exists(key, "file") then return nativefs.read(key) end
	return nil
end

local paths = {
	images = {},
	audio = {},
	atlases = {},
	fonts = {},
	persistantAssets = {"assets/music/freakyMenu.ogg"}
}

function paths.addPersistant(path)
	if not table.find(paths.persistantAssets, path) then
		table.insert(paths.persistantAssets, path)
	end
end

function paths.isPersistant(path)
	for _, k in pairs(paths.persistantAssets) do
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
			o:release()
			paths.audio[k] = nil
		end
	end
	for k, o in pairs(paths.atlases) do
		if not paths.isPersistant(k) then
			o.texture:release()
			for _, f in ipairs(o.frames) do f.quad:release() end
			paths.atlases[k] = nil
		end
	end
	collectgarbage()
end

function paths.getPath(key) return "assets/" .. key end

function paths.exists(path, infotype)
	local info = love.filesystem.getInfo(path)
	return info and info.type == infotype:lower()
end

function paths.getText(key)
	return readFile(paths.getMods("data/" .. key .. ".txt")) or
		readFile(paths.getPath("data/" .. key .. ".txt"))
end

function paths.getJSON(key)
	local data = readFile(paths.getMods(key .. ".json")) or
		readFile(paths.getPath(key .. ".json"))
	if data then
		return decodeJson(data)
	else
		return nil
	end
end

function paths.getFont(key, size)
	if size == nil then size = 12 end

	local path
	local obj
	if Mods.currentMod then
		path = paths.getMods("fonts/" .. key)
		obj = paths.fonts[path .. "_" .. size]
		if obj then return obj end
		if paths.exists(path, "file") then
			obj = love.graphics.newFont(path, size)
			paths.fonts[path .. "_" .. size] = obj
			return obj
		end
	end
	path = paths.getPath("fonts/" .. key)
	obj = paths.fonts[path .. "_" .. size]
	if obj then return obj end
	if paths.exists(path, "file") then
		obj = love.graphics.newFont(path, size)
		paths.fonts[path .. "_" .. size] = obj
		return obj
	end

	print('oh no its returning "font" null NOOOO: ' .. path)
	return nil
end

function paths.getImage(key)
	local path
	local obj
	if Mods.currentMod then
		path = paths.getModsImage(key)
		obj = paths.images[path]
		if obj then return obj end
		if paths.exists(path, "file") then
			obj = love.graphics.newImage(path)
			paths.images[path] = obj
			return obj
		end
	end
	path = paths.getPath("images/" .. key .. ".png")
	obj = paths.images[path]
	if obj then return obj end
	if paths.exists(path, "file") then
		obj = love.graphics.newImage(path)
		paths.images[path] = obj
		return obj
	end

	print('oh no its returning "image" null NOOOO: ' .. key)
	return nil
end

function paths.getAudio(key, stream)
	local path
	local obj
	if Mods.currentMod then
		path = paths.getModsAudio(key)
		obj = paths.audio[path]
		if obj then return obj end
		if paths.exists(path, "file") then
			obj = stream and love.audio.newSource(path, "stream") or
				love.sound.newSoundData(path)
			paths.audio[path] = obj
			return obj
		end
	end
	path = paths.getPath(key .. ".ogg")
	obj = paths.audio[path]
	if obj then return obj end
	if paths.exists(path, "file") then
		obj = stream and love.audio.newSource(path, "stream") or
			love.sound.newSoundData(path)
		paths.audio[path] = obj
		return obj
	end

	print('oh no its returning "audio" null NOOOO: ' .. key)
	return nil
end

function paths.getMusic(key) return paths.getAudio("music/" .. key, true) end

function paths.getSound(key) return paths.getAudio("sounds/" .. key, false) end

function paths.getInst(song)
	local daSong = paths.formatToSongPath(song)
	return paths.getAudio("songs/" .. daSong .. "/Inst", true)
end

function paths.getVoices(song)
	local daSong = paths.formatToSongPath(song)
	return paths.getAudio("songs/" .. daSong .. "/Voices", true)
end

function paths.getSparrowAtlas(key)
	local imgPath, xmlPath
	local obj
	if Mods.currentMod then
		imgPath, xmlPath = key, paths.getMods("images/" .. key .. ".xml")
		obj = paths.atlases[paths.getMods("images/" .. key)]
		if obj then return obj end
		local img = paths.getImage(imgPath)
		if img and paths.exists(xmlPath, "file") then
			obj = Sprite.getFramesFromSparrow(img, readFile(xmlPath))
			paths.atlases[paths.getMods("images/" .. key)] = obj
			return obj
		end
	end
	imgPath, xmlPath = key, paths.getPath("images/" .. key .. ".xml")
	obj = paths.atlases[paths.getPath("images/" .. key)]
	if obj then return obj end
	img = paths.getImage(imgPath)
	if img and paths.exists(xmlPath, "file") then
		obj = Sprite.getFramesFromSparrow(img, readFile(xmlPath))
		paths.atlases[paths.getPath("images/" .. key)] = obj
		return obj
	end

	return nil
end

function paths.getPackerAtlas(key)
	local imgPath, txtPath
	local obj
	if Mods.currentMod then
		imgPath, txtPath = key, paths.getMods("images/" .. key .. ".txt")
		obj = paths.atlases[paths.getMods("images/" .. key)]
		if obj then return obj end
		local img = paths.getImage(imgPath)
		if img and paths.exists(txtPath, "file") then
			obj = Sprite.getFramesFromPacker(img, readFile(txtPath))
			paths.atlases[paths.getMods("images/" .. key)] = obj
			return obj
		end
	end
	imgPath, txtPath = key, paths.getPath("images/" .. key .. ".txt")
	obj = paths.atlases[paths.getPath("images/" .. key)]
	if obj then return obj end
	local img = paths.getImage(imgPath)
	if img and paths.exists(txtPath, "file") then
		obj = Sprite.getFramesFromPacker(img, readFile(txtPath))
		paths.atlases[paths.getPath("images/" .. key)] = obj
		return obj
	end

	return nil
end

function paths.getAtlas(key)
	if paths.exists(paths.getMods('images/' .. key .. '.xml'), "file") or
		paths.exists(paths.getPath('images/' .. key .. '.xml'), "file") then
		return paths.getSparrowAtlas(key)
	end
	return paths.getPackerAtlas(key)
end

function paths.getLua(key)
	local path
	if Mods.currentMod then
		path = paths.getMods(key .. ".lua")
		if paths.exists(path, "file") then
			local chunk = love.filesystem.load(path)
			return chunk
		end
	end
	path = paths.getPath(key .. ".lua")
	if paths.exists(path, "file") then
		local chunk = love.filesystem.load(path)
		return chunk
	end
	return nil
end

local invalidChars = '[~&\\;:<>#]'
local hideChars = '[.,\'"%?!]'
function paths.formatToSongPath(path)
	return string.lower(string.gsub(string.gsub(path:gsub(' ', '-'),
			invalidChars, '-'), hideChars,
		''))
end

function paths.getMods(key)
	if Mods.currentMod then
		return "mods/" .. Mods.currentMod .. "/" .. key
	else
		return "mods/" .. key
	end
end

function paths.getModsImage(key)
	return paths.getMods("images/" .. key .. ".png")
end

function paths.getModsAudio(key)
	return paths.getMods(key .. ".ogg")
end

return paths
