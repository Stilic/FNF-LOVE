local vanilla = {name = "Vanilla"}

local function set(tbl, key, v) if v ~= nil then tbl[key] = v end end

local function compareInsert(noteList, newNote)
	for i, existingNote in ipairs(noteList) do
		if existingNote.t == newNote.t and existingNote.d == newNote.d then
			if (newNote.l > existingNote.l) or
				(newNote.l == existingNote.l and newNote.k ~= nil and
				existingNote.k == nil) or
				(newNote.l == existingNote.l and newNote.k == existingNote.k
				and newNote.gf and not existingNote.gf) then

				noteList[i] = newNote
			end
			return
		end
	end
	table.insert(noteList, newNote)
end

local function getStuff(data, eventData, bpm)
	local dad, bf, events, bpmChanges =
		{}, {}, {}, Conductor.newBPMChanges(bpm)

	local time, steps, total, add, focus, lastFocus = 0, 0, 0

	if eventData then
		local edata = eventData.events or eventData
		for _, e in ipairs(edata) do
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
				local column, gf = n[2], kind == "gf"
				local hit = s.mustHitSection
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
					gf = gf or not hit and s.gfSection
				}
				compareInsert(hit and bf or dad, newNote)
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

function vanilla.parse(data, eventData, meta)
	local chart = table.clone(vanilla.base)
	local realData = data.song

	set(chart, "song", realData.song)

	if meta then vanilla.getFromMeta(meta, chart) end

	set(chart, "bpm", realData.bpm)
	set(chart, "speed", realData.speed)

	set(chart, "stage", realData.stage)
	set(chart, "skin", realData.skin)

	set(chart, "player1", realData.player1)
	set(chart, "player2", realData.player2)
	set(chart, "gfVersion", realData.gfVersion)

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

	if realData.notes then
		chart.notes, chart.events, chart.bpmChanges =
			getStuff(realData.notes, eventData or realData.events, chart.bpm)
	end

	return chart
end

function vanilla.getFromMeta(data, tbl)
	local info = {}

	if data then
		set(tbl, "song", data.songName or data.song)
		set(tbl, "stage", data.stage)
		set(tbl, "skin", data.skin)

		set(tbl, "difficulties", data.difficulties)

		local char = data.characters or data
		set(tbl, "player1", char.player)
		set(tbl, "player2", char.opponent)
		set(tbl, "gfVersion", char.girlfriend)
	end

	return data
end

return vanilla
