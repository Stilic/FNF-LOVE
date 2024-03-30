local Notefield = ActorGroup:extend("Notefield")

function Notefield:new(x, y, keys, noteskin)
	Notefield.super.new(self, x, y)
	noteskin = noteskin or "normal"

	self.noteWidth = math.floor(170 * 0.67)
	self.height = 500
	self.keys = keys
	self.noteskin = noteskin
	self.speed = 1

	self.time = 0
	self.drawSize = 800
	self.maxNotes = 1028

	self.hits = 0
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0

	local startx, y = -self.noteWidth / 2 - (self.noteWidth * keys / 2), -self.height / 2
	self.lanes = {}
	self.receptors = {}
	self.notes = {}

	for i = 1, keys do
		local lane = ActorGroup(startx + self.noteWidth * i, 0, 0, false)
		lane.receptor = Receptor(0, y, i - 1, noteskin)
		lane.renderedNotes, lane.renderedNotesI = {}, {}
		lane.currentNoteI = 1
		lane.drawSize = 1
		lane.speed = 1

		lane:add(lane.receptor)

		self.receptors[i] = lane.receptor
		self.lanes[i] = lane
		self:add(lane)
	end

	self:getWidth()
end

function Notefield:makeNote(time, col, sustain, noteskin)
	local note = Note(time, col, sustain, noteskin or self.noteskin)
	return note, self:addNote(note)
end

function Notefield:addNote(note, from)
	local size = #self.notes
	from = from or size

	local reverse = (self.notes[from] or note).time > note.time
	local i = from < 1 and (reverse and size or 1) or from + (reverse and -1 or 1)
	while reverse and i > 0 or i <= size do
		if reverse then if self.notes[i].time <= time then break end elseif self.notes[i].time > time then break end
		i = reverse and i - 1 or i + 1
	end

	table.insert(self.notes, i, note)
	return i
end

function Notefield:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = game.width / 2 end
	if axes:find("y") then self.y = game.height / 2 end
	if axes:find("z") then self.z = 0 end
	return self
end

function Notefield:getWidth()
	self.width = self.noteWidth * self.keys
	return self.width
end

function Notefield:getHeight()
	return self.height
end

function Notefield:__prepareLane(column, lane, time)
	local notes, receptor, speed, drawSize = self.notes, lane.receptor,
		self.speed * lane.speed,
		self.drawSize * lane.drawSize

	local repy, size = receptor.y, #notes
	local noteI = math.clamp(lane.currentNoteI, 1, size)
	while noteI < size and (notes[noteI + 1].column ~= column or Note.toPos(notes[noteI + 1].time - time, speed) < repy) do noteI = noteI + 1 end
	while noteI > 1 and (Note.toPos(notes[noteI - 1].time - time, speed) >= repy) do noteI = noteI - 1 end
	lane.currentNoteI = noteI

	local renderedNotes, renderedNotesI = lane.renderedNotes, lane.renderedNotesI
	table.clear(renderedNotesI)
	while noteI < size do
		local note = notes[noteI]
		if note.column == column then 
			local y = Note.toPos(note.time - time, speed) + repy
			if y > drawSize - repy then break end

			local prevlane = note.lane
			if prevlane ~= lane then
				if prevlane then prevlane:remove(note) end
				table.insert(renderedNotes, note)
				lane:add(note)
				note.lane = lane
			end

			renderedNotesI[note] = true
			note.y = y
		end

		noteI = noteI + 1
	end

	for i, note in ipairs(renderedNotes) do
		if not renderedNotesI[note] then
			note.lane = nil
			lane:remove(note)
			table.delete(renderedNotes, note)
		end
	end
end

function Notefield:__render(camera)
	local time = self.time
	for i, lane in ipairs(self.lanes) do
		self:__prepareLane(i - 1, lane, time)
	end

	Notefield.super.__render(self, camera)
end

return Notefield
