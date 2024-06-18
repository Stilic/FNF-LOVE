local API = {}
-- this is supposed to be called ChartParser instead but ill probably
-- add other functions for parsing or getting stuff or idk. who knows
-- todo that shouldn't be here: think a way to make erect songs stuff…
---kaoy

API.chart = {
	defaultMeta = {
		songName = nil,
		playData = {
			characters = {
				player = "bf",
				opponent = "dad",
				girlfriend = "gf"
			},
			stage = "stage",
			skin = "default"
		},
		artist = nil,
		charter = nil
	}
}

local function merge(tbl1, tbl2)
	local result = {}
	for key, value in pairs(tbl1) do result[key] = value end
	for key, value in pairs(tbl2) do result[key] = value end
	return result
end
local function sortByTime(a, b) return a.t < b.t end

function API.chart.parse(song, diff, returnRaw)
	local isV2 = true
	-- pretty sure this can be done other way but eh whatever
	local path = "songs/" .. song .. "/chart" -- default fallback for now
	local data = paths.getJSON(path)

	local parsedData = {events = {}; notes = {}}

	if data == nil then
		path = "songs/" .. song .. "/charts/" .. diff:lower() or
			PlayState.defaultDifficulty
		data = paths.getJSON(path)
		isV2 = false
	end

	local meta = merge(API.chart.defaultMeta, paths.getJSON("songs/" .. song .. "/meta"))
	local chart = data.song or {}

	parsedData.song = chart.song or meta.songName or song:capitalize()
	parsedData.bpm = chart.bpm or 100
	parsedData.speed = chart.speed or 1
	parsedData.noVoices = false

	parsedData.artist = meta.artist
	parsedData.charter = meta.charter

	parsedData.stage = chart.stage or meta.playData.stage
	parsedData.skin = chart.skin or meta.playData.skin

	local char = meta.playData.characters
	parsedData.player1 = chart.player1 or char.player
	parsedData.player2 = chart.player2 or char.opponent
	parsedData.gfVersion = chart.gfVersion or char.girlfriend

	if isV2 then
		local speed = data.scrollSpeed and (data.scrollSpeed[diff:lower()] or
			data.scrollSpeed.default) or 1
		parsedData.speed = speed

		parsedData.notes = API.chart.splitNotes(data.notes[diff:lower()])
		parsedData.events = data.events
	else
		parsedData.notes = API.chart.splitNotes(chart.notes, true)
		parsedData.events = API.chart.getV1Events(chart.notes, parsedData.bpm)
	end

	for _, notes in ipairs(parsedData.notes) do
		table.sort(notes, sortByTime)
	end
	table.sort(parsedData.events, sortByTime)

	return returnRaw and data or parsedData
end

function API.chart.splitNotes(data, isV1)
	local dad, bf = {}, {}
	if isV1 then
		for _, s in ipairs(data) do
			if s and s.sectionNotes then
				for _, n in ipairs(s.sectionNotes) do
					local col, time, length = tonumber(n[2]), tonumber(n[1]),
						tonumber(n[3]) or 0
					local hit = s.mustHitSection
					if col > 3 then hit = not hit end

					if hit then table.insert(bf, {t = time, d = col % 4, l = length}) end
					if not hit then table.insert(dad, {t = time, d = col % 4, l = length}) end
				end
			end
		end
	else
		for _, n in ipairs(data) do
			local col, time, length = tonumber(n.d), tonumber(n.t), tonumber(n.l) or 0
			local hit = true
			if col > 3 then hit = false end

			if hit then table.insert(bf, {t = time, d = col % 4, l = length}) end
			if not hit then table.insert(dad, {t = time, d = col % 4, l = length}) end
		end
	end
	return {enemy = dad, player = bf}
end

local function getCrotchet(bpm) return (60 / bpm) * 1000 end
function API.chart.getV1Events(data, bpm)
	local result, time, crotchet, focus, lastFocus = {}, 0, getCrotchet(bpm)
	for _, s in ipairs(data) do
		if s then
			if s.changeBPM and s.bpm ~= bpm then
				bpm = s.bpm
				crotchet = getCrotchet(bpm)
			end
			focus = s.gfSection and 2 or (s.mustHitSection and 1 or 0)
			if focus ~= lastFocus then
				table.insert(result, {
					t = time,
					e = "FocusCamera",
					v = focus
				})
				lastFocus = focus
			end
		end
		time = time + crotchet * 4
	end
	return result
end

return API
