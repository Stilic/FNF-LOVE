local f = "funkin.backend.parser.stage."

local vslice = f..'vslice'

local StageParse = {}

function StageParse.get(stage)
    return paths.getJSON('data/stages/' .. stage)
end

function StageParse.getParser(data)
	if data.version ~= nil then
		return vslice
	end
	return love
end

return StageParse