local Notefield = ActorGroup:extend("Notefield")

local safeZoneOffset = 0.189
Notefield.ratings = {
	{name = "perfect",	time = 0.027,			score = 350, splash = true,  mod = 1.2},
	{name = "sick",		time = 0.045,			score = 350, splash = true,  mod = 1.0},
	{name = "good",		time = 0.094,			score = 200, splash = false, mod = 0.7},
	{name = "bad",		time = 0.140,			score = 100, splash = false, mod = 0.4},
	{name = "shit",		time = safeZoneOffset,	score = 50,  splash = false, mod = 0.2}
}

function Notefield.getRating(a, b, returnShit)
	local diff = math.abs(a - b)
	for i, r in ipairs(Notefield.ratings) do
		if diff <= r.time then return r, i end
	end
	return returnShit and Notefield.ratings[#Notefield.ratings] or nil
end

function Notefield.checkDiff(note, time)
	return note.time > time - safeZoneOffset * note.lateHitMult and
		note.time < time + safeZoneOffset * note.earlyHitMult
end

function Notefield:new(x, y, keys, character, noteskin)
	Notefield.super.new(self, x, y)
	noteskin = noteskin or "normal"

	self.noteWidth = math.floor(170 * 0.67)
	self.height = 500
	self.keys = keys
	self.character = character
	self.noteskin = noteskin
	self.speed = 1
	self.hitsoundVolume = 0
	self.hitsound = paths.getSound('hitsound')

	self.time = 0
	self.offsetTime = 0
	self.drawSize = game.height + self.noteWidth
	self.drawSizeOffset = 0
	self.maxNotes = 1028

	self.totalHits = 0
	self.misses = 0
	self.perfects = 0
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0
	self.hitCallback = nil
	self.missCallback = nil

	local startx = -self.noteWidth / 2 - (self.noteWidth * keys / 2)
	self.lastPress = {}
	self.pressed = {}
	self.lanes = {}
	self.receptors = {}
	self.hitNotes = {}
	self.missedNotes = {}
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
	self.pressed[column] = false
	self.lastPress[column] = 0
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

function Notefield:copyNotesfromNotefield(notefield)
	local clone = {}
	for i, note in ipairs(notefield.notes) do
		local noteClone = note:clone()
		noteClone.parent = self
		noteClone.lane = nil

		clone[i] = noteClone
	end

	table.merge(self.notes, clone)
end

function Notefield:removeNotefromIndex(idx, dontClearHits)
	local note = self.notes[idx]
	if not note then return end
	if not dontClearHits then
		table.delete(self.missedNotes, note)
		table.delete(self.hitNotes, note)
		note.parent = nil
	end

	local lane = note.lane
	if lane then
		note.lane, lane.renderedNotesI[note] = nil
		lane:remove(note)
		table.delete(lane.renderedNotes, note)
	end

	return table.remove(self.notes, idx)
end

function Notefield:removeNote(note, dontClearHits)
	local idx = table.find(self.notes, note)
	if idx then
		return self:removeNotefromIndex(idx, dontClearHits)
	elseif not dontClearHits then
		table.delete(self.missedNotes, note)
		table.delete(self.hitNotes, note)
	end
end

function Notefield:getNotes(time, column)
	local gotNotes, notes = {}, self.notes
	local i, size = 1, #notes
	if size == 0 then return gotNotes end

	local offset = time - safeZoneOffset
	while i < size and offset >= notes[i + 1].time do i = i + 1 end
	while i > 1 and offset < notes[i - 1].time do i = i - 1 end
	while i <= size do
		local n = notes[i]
		local dont = n.tooLate or n.hit
		if not Notefield.checkDiff(n, time) and not dont then break end
		if not dont and n.column == column then
			table.insert(gotNotes, n)
		end
		i = i + 1
	end

	return gotNotes
end

function Notefield:hit(time, note, force)
	local sus = note.sustain and note.hit
	local notetime = sus and note.time + note.sustainTime or note.time
	local rating = Notefield.getRating(notetime, time, sus)
	if not rating then return self:miss(note, force) end

	if not note.hit then
		table.insert(self.hitNotes, note)
		note.hit = true

		local name = rating.name .. "s"
		self.totalHits = self.totalHits + rating.mod
		self[name] = (self[name] or 0) + 1
		(self.hitCallback or __NULL__)(rating, note, force)
	end

	if force or not note.sustain then
		self:removeNote(note, true)
		note.wasGoodHit = true
	end

	return rating
end

function Notefield:miss(note, force)
	if not note.tooLate then
		table.insert(self.missedNotes, note)
		note.tooLate = true

		if not note.ignoreNote then
			self.misses = self.misses + 1
		end
		(self.missCallback or __NULL__)(note, force)
	end

	if force or not note.sustain then
		self:removeNote(note, true)
	end
end

function Notefield:press(time, column, play)
	time = time or self.time

	local fixedColumn, gotNotes = column + 1, self:getNotes(time, column)
	local missed = #gotNotes == 0

	self.lastPress[fixedColumn] = time
	self.pressed[fixedColumn] = true
	local isSustain, rating
	if not missed then
		local coolNote = gotNotes[1]

		for i = 2, #gotNotes do
			local n = gotNotes[i]
			if n.time - coolNote.time <= 0.001 then
				if n.sustainTime > coolNote.sustainTime then
					self:hit(time, coolNote, true)
					gotNotes[i], gotNotes[1], coolNote = coolNote, n, n
				else
					self:hit(time, n, true)
				end
			end
		end

		rating = self:hit(time, coolNote)
		isSustain = coolNote.sustain ~= nil
		self.pressed[fixedColumn] = coolNote

		if play and self.hitsoundVolume > 0 and self.hitsound then
			game.sound.play(self.hitsound, hitsoundVolume)
		end
	end

	if play then
		local receptor = self.receptors[column + 1]
		if receptor then
			receptor:play(missed and "pressed" or "confirm", true)
			if not missed and isSustain then receptor.strokeTime = -1 end
		end

		local char = self.character
		if char then
			char:sing(column)
			if not missed and isSustain then char.strokeTime = -1 end
		end
	end

	return not missed, rating, gotNotes
end

function Notefield:release(time, column, play)
	local fixedColumn = column + 1
	local note = self.pressed[fixedColumn]
	self.pressed[fixedColumn] = nil
	if not note then return end

	local hit, rating = note ~= true
	time = time or self.time
	if hit then
		if note.sustain and note.hit then
			rating = self:hit(time, note, true)
		end
	end

	if play then
		local receptor = self.receptors[fixedColumn]
		if receptor then
			receptor:play("static", true)
		end

		if hit then
			local char = self.character
			if char and char.columnAnim == column then
				char.strokeTime = 0
			end
		end
	end

	return hit, rating, note
end

function Notefield:update(dt)
	Notefield.super.update(self, dt)

	local time = self.time
	for i, note in pairs(self.pressed) do
		if note ~= true and note and note.sustain and time > note.time + note.sustainTime then
			local receptor = self.receptors[note.column + 1]
			if receptor then
				receptor.strokeTime = 0
			end

			local char = self.character
			if char and char.columnAnim == note.column then
				char.strokeTime = 0
			end
		end
	end

	local notes = self.notes
	local offset, i = time - safeZoneOffset, 1
	while i <= #notes do
		local note = notes[i]
		if offset <= note.time then break end

		if not note.hit and not note.tooLate then
			self:miss(note)
		elseif note.sustain and offset > note.time + note.sustainTime then
			if note.hit then
				self:hit(offset, note, true)
			else
				self:miss(note, true)
			end
		else
			i = i + 1
		end
	end
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
	local notes, receptor, speed, drawSize, drawSizeOffset =
		self.notes, lane.receptor,
		self.speed * lane.speed,
		self.drawSize * lane.drawSize,
		self.drawSizeOffset

	local size = #notes
	if size == 0 then return end

	local repx, repy, repz = receptor.x, receptor.y, receptor.z
	local offset, noteI = (-drawSize / 2) - repy + drawSizeOffset, math.clamp(lane.currentNoteI, 1, size)
	while noteI < size and not (notes[noteI].hit or notes[noteI].tooLate) and
		(notes[noteI + 1].column ~= column or Note.toPos(notes[noteI + 1].time - time, speed) <= offset)
	do
		noteI = noteI + 1
	end
	while noteI > 1 and (Note.toPos(notes[noteI - 1].time - time, speed) > offset) do noteI = noteI - 1 end
	lane.currentNoteI = noteI

	local renderedNotes, renderedNotesI = lane.renderedNotes, lane.renderedNotesI
	table.clear(renderedNotesI)

	local reprx, repry, reprz = receptor.noteRotations.x, receptor.noteRotations.y, receptor.noteRotations.z
	local repox, repoy, repoz = receptor.noteOffsets.x, receptor.noteOffsets.y, receptor.noteOffsets.z
	while noteI <= size do
		local note = notes[noteI]
		local y = Note.toPos(note.time - time, speed)
		if note.column == column and (y > offset or note.hit or note.tooLate) then
			if y > drawSize / 2 + drawSizeOffset - repy then break end

			renderedNotesI[note] = true
			local prevlane = note.lane
			if prevlane ~= lane then
				if prevlane then prevlane:remove(note) end
				table.insert(renderedNotes, note)
				lane:add(note)
				note.lane = lane
			end

			-- todo: render path here
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
	local time = self.time - self.offsetTime
	for i, lane in ipairs(self.lanes) do
		self:__prepareLane(i - 1, lane, time)
	end

	Notefield.super.__render(self, camera)
end

return Notefield
