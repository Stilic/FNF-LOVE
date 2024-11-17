local chart = require "funkin.backend.parser.chart"

local Parser = {}

local function sortByTime(a, b) return a.t < b.t end

function Parser.getChart(songName, diff)
	local data, path = chart.get(paths.formatToSongPath(songName), diff and diff:lower() or "normal")
	if data then
		local parser = chart.getParser(data)
		local parsed =
			parser.parse(data, paths.getJSON(path .. "events"),
				paths.getJSON(path .. "meta"), diff)

		table.sort(parsed.notes.enemy, sortByTime)
		table.sort(parsed.notes.player, sortByTime)
		table.sort(parsed.events, sortByTime)

		print("[CHART PARSER] Parsed \"" .. parsed.song .. "\" as " .. (parser.name or "unknown"))
		return parsed
	else
		return table.clone(chart.base)
	end
end

function Parser.getCharacter(charName)
end

return Parser
