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
		if song == "test" then
			parsedData.stage = "test"
		elseif song == "spookeez" or song == "south" or song == "monster" then
			parsedData.stage = "spooky"
		elseif song == "pico" or song == "philly-nice" or song == "blammed" then
			parsedData.stage = "philly"
		elseif song == "satin-panties" or song == "high" or song == "milf" then
			parsedData.stage = "limo"
		elseif song == "cocoa" or song == "eggnog" then
			parsedData.stage = "mall"
		elseif song == "winter-horrorland" then
			parsedData.stage = "mall-evil"
		elseif song == "senpai" or song == "roses" then
			parsedData.stage = "school"
		elseif song == "thorns" then
			parsedData.stage = "school-evil"
		elseif song == "ugh" or song == "guns" or song == "stress" then
			parsedData.stage = "tank"
		else
			parsedData.stage = meta.playData.stage
		end
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
			["mall"] = function() parsedData.gfVersion = "gf-christmas" end,
			["mall-evil"] = function() parsedData.gfVersion = "gf-christmas" end,
			["school"] = function() parsedData.gfVersion = "gf-pixel" end,
			["school-evil"] = function() parsedData.gfVersion = "gf-pixel" end,
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

			parsedData.notes = API.chart.splitNotes(data.notes[diff:lower()])
			parsedData.events = data.events
		else
			parsedData.notes = API.chart.splitNotes(chart.notes, true)
			parsedData.events = API.chart.getV1Events(chart.notes, parsedData.bpm)
		end
	else
		parsedData.notes, parsedData.events = {enemy = {}, player = {}}, {}
	end

	table.sort(parsedData.notes.enemy, sortByTime)
	table.sort(parsedData.notes.player, sortByTime)
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
