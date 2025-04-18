local f = "funkin.backend.parser.character."

local CharacterParser = {}

local love = require(f .. "love")
local vslice = require(f .. "vslice")
local psych = require(f .. "psych")
local codename = require(f .. "codename")

function CharacterParser.get(charName)
	return paths.getJSON("data/characters/" .. charName)
end

function CharacterParser.getParser(data)
	if data.version ~= nil then
		return vslice
	elseif data.image ~= nil and data.sprite == nil then
		return psych
	elseif --[[todo: detect if the data is an xml]] then
		return codename
	end
	return love
end

return CharacterParser
