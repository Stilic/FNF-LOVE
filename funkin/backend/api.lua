local API = {}
--[[
this is supposed to be called ChartParser instead but ill probably
add other functions for parsing or getting stuff or idk. who knows
todo that shouldn't be here: think a way to make erect songs stuff…
-kaoy
]]

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

local function sortByTime(a, b) return a.t < b.t end
function API.chart.parse(song, diff, returnRaw)
	if song then
		song = paths.formatToSongPath(song)
	else
		return
	end

	local isV2 = true
	-- pretty sure this can be done other way but eh whatever
	local path = "songs/" .. song .. "/chart" -- default fallback for now
	local data = paths.getJSON(path)

	local parsedData = {events = {}, notes = {}}

	if not data then
		path = "songs/" .. song .. "/charts/" .. diff:lower() or
			PlayState.defaultDifficulty
		data = paths.getJSON(path)
		isV2 = false
	end

	local meta, chart =
		table.merge(API.chart.defaultMeta, paths.getJSON("songs/" .. song .. "/meta")),
		data and data.song or {}
	if not meta then meta = table.clone(API.chart.defaultMeta) end

	parsedData.song = chart.song or meta.songName or song:capitalize()
	parsedData.bpm = chart.bpm or 100
	parsedData.speed = chart.speed or 1

	parsedData.artist = meta.artist
	parsedData.charter = meta.charter

	if chart.stage then
		parsedData.stage = chart.stage
	else
		switch(song, {
			["test"] = function() parsedData.stage = "test" end,
			[{"spookeez", "south", "monster"}] = function() parsedData.stage = "spooky" end,
			[{"pico", "philly-nice", "blammed"}] = function() parsedData.stage = "philly" end,
			[{"satin-panties", "high", "milf"}] = function() parsedData.stage = "limo" end,
			[{"cocoa", "eggnog"}] = function() parsedData.stage = "mall" end,
			["winter-horrorland"] = function() parsedData.stage = "mall-evil" end,
			[{"senpai", "roses"}] = function() parsedData.stage = "school" end,
			["thorns"] = function() parsedData.stage = "school-evil" end,
			[{"ugh", "guns", "stress"}] = function() parsedData.stage = "tank" end,
			default = function() parsedData.stage = meta.playData.stage end
		})
	end
	parsedData.skin = chart.skin or meta.playData.skin

	local char = meta.playData.characters
	parsedData.player1 = chart.player1 or char.player
	parsedData.player2 = chart.player2 or char.opponent
	if chart.gfVersion then
		parsedData.gfVersion = chart.gfVersion
	else
		switch(parsedData.stage, {
			["limo"] = function() parsedData.gfVersion = "gf-car" end,
			[{"mall", "mall-evil"}] = function() parsedData.gfVersion = "gf-christmas" end,
			[{"school", "school-evil"}] = function() parsedData.gfVersion = "gf-pixel" end,
			["tank"] = function()
				if song == "stress" then
					parsedData.gfVersion = "pico-speaker"
				else
					parsedData.gfVersion = "gf-tankmen"
				end
			end,
			default = function()
				parsedData.gfVersion = char.girlfriend
			end
		})
	end

	if data then
		if isV2 then
			local speed = data.scrollSpeed and (data.scrollSpeed[diff:lower()] or
				data.scrollSpeed.default) or 1
			parsedData.speed = speed

			parsedData.notes, parsedData.events, parsedData.bpmChanges =
				API.chart.readDiff(parsedData.bpm, data.notes[diff:lower()])
		else
			parsedData.notes, parsedData.events, parsedData.bpmChanges =
				API.chart.readDiff(parsedData.bpm, chart.notes, true)
		end
	else
		parsedData.notes, parsedData.events, parsedData.bpmChanges =
			{enemy = {}, player = {}}, {}, {}
	end

	table.sort(parsedData.notes.enemy, sortByTime)
	table.sort(parsedData.notes.player, sortByTime)
	table.sort(parsedData.events, sortByTime)

	return returnRaw and data or parsedData
end

function API.chart.readDiff(bpm, data, isV1)
	local dad, bf, events, bpmChanges =
		{}, {}, {}, Conductor.newBPMChanges(bpm)
	if isV1 then
		local time, steps, total,
		add, focus, lastFocus = 0, 0, 0
		for _, s in ipairs(data) do
			if s and s.sectionNotes then
				for _, n in ipairs(s.sectionNotes) do
					local col, time, length, type = tonumber(n[2]), tonumber(n[1]),
						tonumber(n[3]) or 0, tonumber(n[4]) or 0 -- ?
					local hit = s.mustHitSection
					if col > 3 then hit = not hit end

					if hit then table.insert(bf, {t = time, d = col % 4, l = length, k = type}) end
					if not hit then table.insert(dad, {t = time, d = col % 4, l = length, k = type}) end
				end

				focus = s.gfSection and 2 or (s.mustHitSection and 0 or 1)
				if focus ~= lastFocus then
					table.insert(events, {
						t = time,
						e = "FocusCamera",
						v = focus
					})
					lastFocus = focus
				end

				if s.changeBPM and s.bpm ~= nil and s.bpm ~= bpm then
					bpm, total = s.bpm, total + 1
					table.insert(bpmChanges, {
						step = steps,
						time = time,
						bpm = bpm,
						stepCrotchet = Conductor.calculateCrotchet(bpm) / 4,
						id = total
					})
				end

				add = s.sectionBeats and s.sectionBeats * 4 or 16
				steps = steps + add
				time = time + bpmChanges[total].stepCrotchet * add
			end
		end
	else
		for _, n in ipairs(data) do
			local col, time, length = tonumber(n.d), tonumber(n.t), tonumber(n.l) or 0
			local hit = true
			if col > 3 then hit = false end

			if hit then table.insert(bf, {t = time, d = col % 4, l = length, k = n.k}) end
			if not hit then table.insert(dad, {t = time, d = col % 4, l = length, k = n.k}) end
		end
	end
	return {enemy = dad, player = bf}, events, bpmChanges
end

return API
