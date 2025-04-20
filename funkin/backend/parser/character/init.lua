local f = "funkin.backend.parser.character."

local CharacterParser = {}

local love = require(f .. "love")
local vslice = require(f .. "vslice")
local psych = require(f .. "psych")
local codename = require(f .. "codename")

function CharacterParser.get(charName)
	local xml = paths.exists(paths.getPath("data/characters/" .. charName .. ".xml"), "file") and paths.getXML("data/characters/" .. charName).character
	return xml or paths.getJSON("data/characters/" .. charName)
end

function CharacterParser.getParser(data)
	if data.version ~= nil then
		return vslice
	elseif data.image ~= nil and data.sprite == nil then
		return psych
	elseif data.children ~= nil then
		return codename
	end
	return love
end

return CharacterParser
