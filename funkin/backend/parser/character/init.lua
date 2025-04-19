local f = "funkin.backend.parser.character."

local CharacterParser = {}

local love = require(f .. "love")
local vslice = require(f .. "vslice")
local psych = require(f .. "psych")
local codename = require(f .. "codename")

function CharacterParser.get(charName)
	return paths.getJSON("data/characters/" .. charName) or paths.exists("data/characters/" .. charName .. ".xml") and paths.getXML("data/characters/" .. charName)
end

function CharacterParser.getParser(data)
	if data.version ~= nil then
		return vslice
	elseif data.image ~= nil and data.sprite == nil then
		return psych
	elseif paths.exists("data/characters/" .. charName .. ".xml") then
		return codename
	end
	return love
end

return CharacterParser
