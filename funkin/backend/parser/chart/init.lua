local f = "funkin.backend.parser.chart."

local vanilla = require(f .. "vanilla")
local codename = require(f .. "codename")
local vslice = require(f .. "vslice")

local ChartParse = {}

local base = {
	song = nil,
	bpm = 100,
	speed = 1,

	difficulties = {"Easy", "Normal", "Hard"},

	player1 = nil,
	player2 = nil,
	gfVersion = nil,

	stage = nil,
	skin = nil,

	events = {},
	notes = {
		player = {}, enemy = {}
	},
	timeChanges = nil
}

for _, module in pairs({vanilla, vslice, codename}) do
	module.base = base
end

ChartParse.base = base

function ChartParse.get(song, diff)
	local path, json = "songs/" .. song .. "/"
	if paths.exists(paths.getPath(path .. "charts"), "directory") and
		paths.exists(paths.getPath(path .. "charts/" .. diff .. ".json"), "file") then
		json = paths.getJSON(path .. "charts/" .. diff)
	else
		json = paths.getJSON(path .. "chart-" .. diff)
		if json == nil then
			json = paths.getJSON(path .. "chart")
		end
	end

	return json or table.clone(base), path
end

function ChartParse.getParser(data)
	if data.codenameChart then return codename
	elseif data.version == nil then return vanilla end
	return vslice
end

return ChartParse
