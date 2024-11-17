local vslice = {name = "V-Slice"}

local function set(tbl, key, v) if v ~= nil then tbl[key] = v end end

local function compareInsert(noteList, newNote)
	for i, existingNote in ipairs(noteList) do
		if existingNote.t == newNote.t and existingNote.d == newNote.d then
			if (newNote.l > existingNote.l) or
				(newNote.l == existingNote.l and newNote.k ~= nil and existingNote.k == nil) or
				(newNote.l == existingNote.l and newNote.k == existingNote.k and newNote.gf and not existingNote.gf) then
				noteList[i] = newNote
			end
			return
		end
	end
	table.insert(noteList, newNote)
end

local function getStuff(data)
	local dad, bf = {}, {}

	for _, n in ipairs(data) do
		local column = tonumber(n.d)
		local newNote = {
			t = tonumber(n.t),
			d = column % 4,
			l = tonumber(n.l) or 0,
			k = n.k
		}
		compareInsert(column > 3 and dad or bf, newNote)
	end

	return {enemy = dad, player = bf}
end

function vslice.parse(data, _, meta, diff)
	local chart = table.clone(vslice.base)

	if meta then vslice.getFromMeta(meta, chart) end

	if chart.timeChanges then
		-- todo rework this and change conductor maybe??, fnf base works with different times
		--[[
		t: Timestamp in specified `timeFormat`.
		b: Time in beats (int). The game will calculate further beat values based on this one, so it can do it in a simple linear fashion.
		bpm: Quarter notes per minute (float). Cannot be empty in the first element of the list, but otherwise it's optional,
		and defaults to the value of the previous element.
		n: Time signature numerator (int). Optional, defaults to 4.
		d: Time signature denominator (int). Optional, defaults to 4. Should only ever be a power of two.
		bt: Beat tuplets (Array<int> or int). This defines how many steps each beat is divided into.
		It can either be an array of length `n` (see above) or a single integer number. Optional, defaults to 4.
		]]
		for i, c in ipairs(chart.timeChanges) do
			if c.t <= 0 then
				chart.bpm = c.bpm
				table.remove(chart.timeChanges, i)
				break
			end
		end
	end

	if data.notes[diff:lower()] then
		local speed = data.scrollSpeed and (data.scrollSpeed[diff:lower()] or
			data.scrollSpeed.default) or 1
		chart.speed = speed
		chart.notes, chart.events =
			getStuff(data.notes[diff:lower()]), data.events
	end

	return chart
end

function vslice.getFromMeta(meta, tbl)
	local data = meta
	local info = {}

	if data then
		local info = data.playData or data
		set(tbl, "song", data.songName or data.song)
		set(tbl, "stage", info.stage)
		set(tbl, "skin", info.skin)

		set(tbl, "difficulties", info.difficulties)
		set(tbl, "timeChanges", data.timeChanges)

		info = info.characters or info
		set(tbl, "player1", info.player)
		set(tbl, "player2", info.opponent)
		set(tbl, "gfVersion", info.girlfriend)
	end

	return data
end

return vslice
