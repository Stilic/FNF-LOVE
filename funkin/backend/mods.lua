local Mods = {
	mods = {},
	currentMod = nil
}

function Mods.getBanner(mods)
	local loadedBanner = nil
	local banner = 'mods/' .. mods .. '/banner.png'
	local obj = paths.images[banner]
	if obj then loadedBanner = obj end
	if paths.exists(banner, "file") then
		obj = love.graphics.newImage(banner)
		paths.images[banner] = obj
		loadedBanner = obj
	else
		local emptyBanner = paths.getPath('images/menus/modsEmptyBanner.png')
		obj = paths.images[emptyBanner]
		if obj then loadedBanner = obj end
		if paths.exists(emptyBanner, "file") then
			obj = love.graphics.newImage(emptyBanner)
			paths.images[emptyBanner] = obj
			loadedBanner = obj
		end
	end
	return loadedBanner
end

function Mods.getMetadata(mods)
	local function readMetaFile()
		if paths.exists("mods", "directory") and paths.exists('mods/' .. mods .. '/meta.json', "file") then
			local json = (require "lib.json").decode(
				love.filesystem.read('mods/' .. mods .. '/meta.json'))
			return json
		end
		return {
			name = "unknown",
			color = "#1F1F1F",
			description = "unknown",
			version = 1
		}
	end

	return readMetaFile()
end

function Mods.loadMods()
	Mods.mods = {}
	if not paths.exists("mods", "directory") then return end

	for _, dir in ipairs(love.filesystem.getDirectoryItems('mods')) do
		if love.filesystem.getInfo('mods/' .. dir, 'directory') ~= nil then
			table.insert(Mods.mods, dir)
		end
	end

	if game.save.data.currentMod then
		Mods.currentMod = game.save.data.currentMod
		if table.find(Mods.mods, Mods.currentMod) then
			Mods.currentMod = game.save.data.currentMod
		else
			Mods.currentMod = nil
			game.save.data.currentMod = Mods.currentMod
		end
	end
end

return Mods
