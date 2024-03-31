local Notefield = ActorGroup:extend("Notefield")

function Notefield:new(x, y, keys, character, noteskin)
	Notefield.super.new(self, x, y)
	noteskin = noteskin or "normal"

	self.noteWidth = math.floor(170 * 0.67)
	self.height = 500
	self.keys = keys
	self.character = character
	self.noteskin = noteskin
	self.speed = 1

	self.time = 0
	self.drawSize = game.height + self.noteWidth / 2
	self.drawSizeOffset = 0
	self.maxNotes = 1028

	self.hits = 0
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0

	local startx = -self.noteWidth / 2 - (self.noteWidth * keys / 2)
	self.lanes = {}
	self.receptors = {}
	self.notes = {}

	for i = 1, keys do
		self:makeLane(i).x = startx + self.noteWidth * i
	end

	self:getWidth()
end

function Notefield:makeLane(column, y)
	local lane = ActorGroup(0, 0, 0, false)
	lane.receptor = Receptor(0, y or -self.height / 2, column - 1, self.noteskin)
	lane.renderedNotes, lane.renderedNotesI = {}, {}
	lane.currentNoteI = 1
	lane.drawSize = 1
	lane.speed = 1

	lane:add(lane.receptor)
	lane.receptor.lane = lane

	self.receptors[column] = lane.receptor
	self.lanes[column] = lane
	self:add(lane)
	return lane
end

function Notefield:makeNote(time, col, sustain, noteskin)
	local note = Note(time, col, sustain, noteskin or self.noteskin)
	return note, self:addNote(note)
end

function Notefield:addNote(note)
	note.parent = self
	table.insert(self.notes, note)
	return note
end

function Notefield:removeNotefromIndex(idx)
	local note = self.notes[idx]
	if not note then return -1 end

	local lane = note.lane
	if lane then
		note.lane, lane.renderedNotesI[note] = nil
		lane:remove(note)
		table.delete(lane.renderedNotes, note)
	end

	note.parent = nil
	return table.remove(self.notes, idx)
end

function Notefield:removeNote(note)
	return self:removeNotefromIndex(table.find(self.notes, note))
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
	local notes, receptor, speed, drawSize, drawSizeOffset = self.notes, lane.receptor,
		self.speed * lane.speed,
		self.drawSize * lane.drawSize,
		self.drawSizeOffset

	local repx, repy, repz, size = receptor.x, receptor.y, receptor.z, #notes
	local offset, noteI = (-drawSize / 2) - repy + drawSizeOffset, math.clamp(lane.currentNoteI, 1, size)
	while noteI < size and (notes[noteI + 1].column ~= column or Note.toPos(notes[noteI + 1].time - time, speed) < offset) do noteI = noteI + 1 end
	while noteI > 1 and (Note.toPos(notes[noteI - 1].time - time, speed) >= offset) do noteI = noteI - 1 end
	lane.currentNoteI = noteI

	local renderedNotes, renderedNotesI = lane.renderedNotes, lane.renderedNotesI
	table.clear(renderedNotesI)

	local reprx, repry, reprz = receptor.noteRotations.x, receptor.noteRotations.y, receptor.noteRotations.z
	local repox, repoy, repoz = receptor.noteOffsets.x, receptor.noteOffsets.y, receptor.noteOffsets.z
	while noteI < size do
		local note = notes[noteI]
		local y = Note.toPos(note.time - time, speed)
		if note.column == column and y > offset then
			if y >= drawSize / 2 + drawSizeOffset - repy then break end

			renderedNotesI[note] = true
			local prevlane = note.lane
			if prevlane ~= lane then
				if prevlane then prevlane:remove(note) end
				table.insert(renderedNotes, note)
				lane:add(note)
				note.lane = lane
			end

			local x, y, z = Actor.worldSpin(0, y, 0, reprx, repry, reprz, repox, repoy, repoz)
			note.x, note.y, note.z = x + repox + repx, y + repoy + repy, z + repoz + repz
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
