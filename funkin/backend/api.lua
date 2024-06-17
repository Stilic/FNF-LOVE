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

local function _merge(tbl1, tbl2)
	local result = {}
	for key, value in pairs(tbl1) do result[key] = value end
	for key, value in pairs(tbl2) do result[key] = value end
	return result
end

function API.getSongMetadata(song)
	local path = "songs/" .. song .. "/meta"
	return paths.getJSON(path)
end

function API.chart.parse(song, diff, returnRaw)
	local _isV2 = true
	-- pretty sure this can be done other way but eh whatever
	local path = "songs/" .. song .. "/chart" -- default fallback for now
	local data = paths.getJSON(path)

	local parsedData = {events = {}; notes = {}}

	if data == nil then
		path = "songs/" .. song .. "/charts/" .. diff:lower() or
			PlayState.defaultDifficulty
		data = paths.getJSON(path)
		_isV2 = false
	end

	local meta = _merge(API.chart.defaultMeta, API.getSongMetadata(song))
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

	if _isV2 then
		local speed = data.scrollSpeed and (data.scrollSpeed[diff:lower()] or
			data.scrollSpeed.default) or 1
		parsedData.speed = speed

		parsedData.notes = data.notes[diff:lower()]
		parsedData.events = data.events
	else
		parsedData.notes = API.chart.convertNotesToV2(chart.notes)
		parsedData.events = API.chart.getV1Events(chart.notes)
	end

	return (returnRaw and data or parsedData)
end

function API.chart.convertNotesToV2(data)
	-- this is broken
	local result = {}
	for _, s in ipairs(data) do
		if s and s.sectionNotes then
			for i, n in ipairs(s.sectionNotes) do
				local time, col = tonumber(n[1]), tonumber(n[2])
				local hit, sustime = s.mustHitSection, tonumber(n[3]) or 0
				if not hit then col = math.abs(col - 7) end

				table.insert(result, {t = time, d = col, l = sustime})
			end
		end
	end
	return result
end

function API.chart.getV1Events(data, initBPM)
	-- wip, figuring out how to do this yet
	local result = {}
	for _, s in ipairs(data) do
		if s and s.sectionNotes then
			for i, n in ipairs(s.sectionNotes) do
				local cam = 0
				if s.mustHitSection then
					cam = 1
					table.insert(result, {
						t = API.chart.measureV1HitSectionTime(i,
							(n.changeBPM and n.bpm or initBPM)),
						e = "FocusCamera", v = cam
					})
				end
			end
		end
	end
	return result
end

function API.chart.measureV1HitSectionTime(section, bpm)
	return 1000 * section
end

return API
