local vslice = {name = "V-Slice"}

local function getFromMeta(meta, tbl)
	assert(meta.playData ~= nil, "Not a valid V-Slice metadata")
	local info = meta.playData

	Parser.pset(tbl, "song", meta.songName or meta.song)
	Parser.pset(tbl, "stage", info.stage)

	local notestyle = info.noteStyle == "funkin" and
		"default" or info.noteStyle == "pixel" and "default-pixel"
		or info.noteStyle
	Parser.pset(tbl, "skin", notestyle)

	Parser.pset(tbl, "difficulties", info.difficulties)
	Parser.pset(tbl, "timeChanges", meta.timeChanges)

	info = info.characters
	Parser.pset(tbl, "player1", info.player)
	Parser.pset(tbl, "player2", info.opponent)
	Parser.pset(tbl, "gfVersion", info.girlfriend)
end

local function getStuff(data)
	local dad, bf = {}, {}

	for _, n in ipairs(data) do
		local column = tonumber(n.d)
		local kind = n.k == "mom" and "alt" or n.k
		local newNote = {
			t = tonumber(n.t),
			d = column % 4,
			l = tonumber(n.l) or 0,
			k = kind
		}
		table.insert(column > 3 and dad or bf, newNote)
	end

	return {enemy = dad, player = bf}
end

function vslice.parse(data, _, meta, diff)
	local chart = Parser.getDummyChart()

	if meta then getFromMeta(meta, chart) end

	if chart.timeChanges then
		-- todo rework this and rework conductor too maybe??
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

return vslice
