local vanilla = {name = "Vanilla/Psych"}

local function getFromMeta(data, tbl)
	Parser.pset(tbl, "song", data.songName or data.song or data.name)
	Parser.pset(tbl, "stage", data.stage)
	Parser.pset(tbl, "skin", data.skin)

	Parser.pset(tbl, "difficulties", data.difficulties)

	local char = data.characters or data
	Parser.pset(tbl, "player1", char.player)
	Parser.pset(tbl, "player2", char.opponent)
	Parser.pset(tbl, "gfVersion", char.girlfriend)
end

local function getStuff(data, eventData, bpm, psych)
	local dad, bf, events, bpmChanges =
		{}, {}, {}, Conductor.newBPMChanges(bpm)

	local time, steps, total, add, focus, lastFocus = 0, 0, 0

	if eventData then
		for _, e in ipairs(eventData) do
			local etime = e[1]
			for _, i in ipairs(e[2]) do
				local eevent = i[1]
				local evalue = {i[2], i[3]}

				table.insert(events, {
					t = etime,
					e = eevent,
					v = evalue,
					psych = true
				})
			end
		end
	end

	for _, s in ipairs(data) do
		if s and s.sectionNotes then
			for _, n in ipairs(s.sectionNotes) do
				local kind = n[4]
				local column, gf = n[2], kind == "gf" or kind == "GF Sing"
				local hit = psych or s.mustHitSection
				if column > 3 then hit = not hit end
				if kind == true or kind == 1 or (not hit and s.altAnim) then
					kind = "alt"
				elseif gf or type(kind) ~= "string" then
					kind = nil
				end

				local newNote = {
					t = n[1],
					d = column % 4,
					l = n[3],
					k = kind,
					gf = gf or (not hit and s.gfSection)
				}
				table.insert(hit and bf or dad, newNote)
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

	return {enemy = dad, player = bf}, events, bpmChanges
end

function vanilla.parse(data, events, meta)
	local baseData = data.song
	data = type(baseData) == "table" and baseData or data

	local chart = Parser.getDummyChart()

	Parser.pset(chart, "song", data.song)

	if meta then getFromMeta(meta, chart) end

	Parser.pset(chart, "bpm", data.bpm)
	Parser.pset(chart, "speed", data.speed)

	Parser.pset(chart, "stage", data.stage)
	Parser.pset(chart, "skin", data.skin)

	Parser.pset(chart, "player1", data.player1)
	Parser.pset(chart, "player2", data.player2)
	Parser.pset(chart, "gfVersion", data.gfVersion)

	local song = paths.formatToSongPath(chart.song)
	if not chart.stage then
		switch(song, {
			["test"] = function() chart.stage = "test" end,
			[{"spookeez", "south", "monster"}] = function() chart.stage = "spooky" end,
			[{"pico", "philly-nice", "blammed"}] = function() chart.stage = "philly" end,
			[{"satin-panties", "high", "milf"}] = function() chart.stage = "limo" end,
			[{"cocoa", "eggnog"}] = function() chart.stage = "mall" end,
			["winter-horrorland"] = function() chart.stage = "mall-evil" end,
			[{"senpai", "roses"}] = function() chart.stage = "school" end,
			["thorns"] = function() chart.stage = "school-evil" end,
			[{"ugh", "guns", "stress"}] = function() chart.stage = "tank" end,
			default = function() chart.stage = "stage" end
		})
	end
	if not chart.skin then
		switch(chart.stage, {
			[{"school", "school-evil"}] = function() chart.skin = "default-pixel" end,
			default = function() chart.skin = "default" end
		})
	end
	if not chart.gfVersion then
		switch(chart.stage, {
			["limo"] = function() chart.gfVersion = "gf-car" end,
			[{"mall", "mall-evil"}] = function() chart.gfVersion = "gf-christmas" end,
			[{"school", "school-evil"}] = function() chart.gfVersion = "gf-pixel" end,
			["tank"] = function()
				chart.gfVersion = song == "stress" and "pico-speaker" or "gf-tankmen"
			end,
			default = function() chart.gfVersion = "gf" end
		})
	end

	if data.notes then
		chart.notes, chart.events, chart.bpmChanges =
			getStuff(data.notes, events or data.events, chart.bpm,
				data.format and data.format:startsWith("psych"))
	end

	return chart
end

return vanilla
