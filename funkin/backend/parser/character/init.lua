local f = "funkin.backend.parser.character."

local CharacterParser = {}

-- i WONT do psych i cant find a way to detect if its from that engine at all
-- neither won't for codename i dont like xml
-- use the coverters disponible on the discord server
local love = require(f .. "love")
local vslice = require(f .. "vslice")

function CharacterParser.get(charName)
	return paths.getJSON("data/characters/" .. charName)
end

function CharacterParser.getParser(data)
	if data.version ~= nil then
		return vslice
	end
	return love
end

return CharacterParser
