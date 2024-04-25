local Notefield = ActorGroup:extend("Notefield")

function Notefield:new(x, y, keys, skin, character, vocals)
	Notefield.super.new(self, x, y)

	self.noteWidth = math.floor(160 * 0.7)
	self.height = 500
	self.keys = keys
	self.skin = skin and paths.getNoteskin(skin) or paths.getNoteskin("default")
	self.character, self.vocals = character, vocals

	-- self.hitsoundVolume, self.hitsound = 0, paths.getSound("hitsound")
	self.vocalVolume = 1

	self.time, self.beat = 0, 0
	self.offsetTime = 0
	self.speed = 1
	self.drawSize = game.height + self.noteWidth
	self.drawSizeOffset = 0
	self.downscroll = false -- this just sets scale y backwards
	self.canSpawnSplash = ClientPrefs.data.noteSplash

	-- for PlayState
	self.bot = false

	self.modifiers = {}

	self.lanes = {}
	self.receptors = {}
	self.notes = {}
	self.held = {}
	self.splashes = {}

	local startx = -self.noteWidth / 2 - (self.noteWidth * keys / 2)
	for i = 1, keys do
		self:makeLane(i).x = startx + self.noteWidth * i
		self.held[i] = {}
	end

	self:getWidth()
end

function Notefield:makeLane(direction, y)
	local lane = ActorGroup(0, 0, 0, false)
	lane.receptor = Receptor(0, y or -self.height / 2, direction - 1, self.skin)
	lane.renderedNotes, lane.renderedNotesI = {}, {}
	lane.currentNoteI = 1
	lane.drawSize, lane.drawSizeOffset = 1, 0
	lane.speed = 1

	lane:add(lane.receptor)
	lane.receptor.lane = lane
	lane.receptor.parent = self

	self.receptors[direction] = lane.receptor
	self.lanes[direction] = lane
	self:add(lane)
	return lane
end

function Notefield:makeNote(time, col, sustain, skin)
	local note = Note(time, col, sustain, skin or self.skin)
	return note, self:addNote(note)
end

function Notefield:addNote(note)
	note.parent = self
	table.insert(self.notes, note)
	return #self.notes
end

function Notefield:copyNotesfromNotefield(notefield)
	for i, note in ipairs(notefield.notes) do
		local parent, grp = note.parent, note.group
		note.parent, note.group = nil

		local noteClone = note:clone()
		noteClone.parent = self

		note.parent, note.group = parent, grp

		table.insert(self.notes, noteClone)
	end

	table.sort(self.notes, Conductor.sortByTime)
end

function Notefield:removeNotefromIndex(idx)
	local note = self.notes[idx]
	if not note then return end
	note.parent = nil

	local lane = note.group
	if lane then
		note.group, lane.renderedNotesI[note] = nil
		lane:remove(note)
		table.delete(lane.renderedNotes, note)
	end

	return table.remove(self.notes, idx)
end

function Notefield:removeNote(note)
	local idx = table.find(self.notes, note)
	if idx then
		return self:removeNotefromIndex(idx)
	end
end

function Notefield:setSkin(skin)
	if self.skin.skin == skin then return end

	skin = skin and paths.getNoteskin(skin) or paths.getNoteskin("default")
	self.skin = skin

	for _, rep in ipairs(self.receptors) do
		rep:setSkin(skin)
	end
	for _, note in ipairs(self.notes) do
		note:setSkin(skin)
	end
end

function Notefield:getNotesToHit(time, direction)
	local notes = self.notes
	if #notes == 0 then return {} end

	local hitNotes, i, started = {}, 1, false
	for _, note in ipairs(notes) do
		if (direction == nil or note.direction == direction) and note:checkDiff(time) then
			if not note.ignoreNote and not note.wasGoodHit and not note.tooLate then
				local prevIdx = i - 1
				local prev = hitNotes[prevIdx]
				if prev and note.time - prev.time <= 0.001 and note.sustainTime > prev.sustainTime then
					hitNotes[i] = prev
					hitNotes[prevIdx] = note
				else
					hitNotes[i] = note
				end
				i = i + 1
				started = true
			end
		elseif started then
			break
		end
	end

	return hitNotes
end

function Notefield:spawnSplash(direction)
	if not self.canSpawnSplash then return end

	local receptor = self.receptors[direction + 1]
	if receptor then
		local splash = receptor:spawnSplash()
		if not splash then return end
		table.insert(self.splashes, splash)
		self:add(splash)
	end
end

function Notefield:update(dt)
	Notefield.super.update(self, dt)

	for i = #self.splashes, 1, -1 do
		local splash = self.splashes[i]
		if splash.animFinished then
			table.remove(self.splashes, i)
			self:remove(splash)
		end
	end

	for _, mod in pairs(self.modifiers) do mod:update(self.beat) end
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

function Notefield:destroy()
	ActorSprite.destroy(self)

	self.modifiers = nil
	if self.receptors then
		for _, r in ipairs(self.receptors) do r:destroy() end
		self.receptors = nil
	end
	if self.notes then
		for _, n in ipairs(self.notes) do n:destroy() end
		self.notes = nil
	end
	if self.lanes then
		for _, l in ipairs(self.lanes) do
			l:destroy(); if l.receptor then l.receptor:destroy() end
			l.renderedNotes, l.renderedNotesI, l.currentNoteI, l.receptor = nil
		end
	end
end

function Notefield:__prepareLane(direction, lane, time)
	local notes, receptor, speed, drawSize, drawSizeOffset =
		self.notes, lane.receptor,
		self.speed * lane.speed,
		self.drawSize * (lane.drawSize or 1),
		self.drawSizeOffset + (lane.drawSizeOffset or 0)

	local size, renderedNotes, renderedNotesI = #notes, lane.renderedNotes, lane.renderedNotesI
	table.clear(renderedNotesI)

	if size == 0 then
		for _, note in ipairs(renderedNotes) do
			note.group = nil
			lane:remove(note)
			table.delete(renderedNotes, note)
		end
		return
	end

	local repx, repy, repz = receptor.x, receptor.y, receptor.z
	local offset, noteI = (-drawSize / 2) - repy + drawSizeOffset, math.clamp(lane.currentNoteI, 1, size)
	while noteI < size and not notes[noteI].sustain and
		(notes[noteI + 1].direction ~= direction or Note.toPos(notes[noteI + 1].time - time, speed) <= offset)
	do
		noteI = noteI + 1
	end
	while noteI > 1 and (Note.toPos(notes[noteI - 1].time - time, speed) > offset) do noteI = noteI - 1 end

	lane._drawSize, lane._drawSizeOffset = lane.drawSize, lane.drawSizeOffset
	lane.drawSize, lane.drawSizeOffset, lane.currentNoteI = drawSize, drawSizeOffset, noteI
	local reprx, repry, reprz = receptor.noteRotations.x, receptor.noteRotations.y, receptor.noteRotations.z
	local repox, repoy, repoz = repx + receptor.noteOffsets.x, repy + receptor.noteOffsets.y, repz + receptor.noteOffsets.z
	while noteI <= size do
		local note = notes[noteI]
		local y = Note.toPos(note.time - time, speed)
		if note.direction == direction and (y > offset or note.sustain) then
			if y > drawSize / 2 + drawSizeOffset - repy then break end

			renderedNotesI[note] = true
			local prevlane = note.group
			if prevlane ~= lane then
				if prevlane then prevlane:remove(note) end
				table.insert(renderedNotes, note)
				lane:add(note)
				note.group = lane
			end

			-- Notes Render are handled in Note.lua
			note._rx, note._ry, note._rz, note._speed = note.rotation.x, note.rotation.y, note.rotation.z, note.speed
			note._targetTime, note.speed, note.rotation.x, note.rotation.y, note.rotation.z =
				time, note._speed * speed, note._rx + reprx, note._ry + repry, note._rz + reprz
		end

		noteI = noteI + 1
	end

	for _, note in ipairs(renderedNotes) do
		if not renderedNotesI[note] then
			note.group = nil
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

	for _, mod in pairs(self.modifiers) do if mod.apply then mod:apply(self) end end
	if self.downscroll then self.scale.y = -self.scale.y end
	Notefield.super.__render(self, camera)
	if self.downscroll then self.scale.y = -self.scale.y end
	NoteModifier.discard()

	for _, lane in ipairs(self.lanes) do
		lane.drawSize, lane.drawSizeOffset = lane._drawSize, lane._drawSizeOffset
		for _, note in ipairs(lane.renderedNotes) do
			note.speed, note.rotation.x, note.rotation.y, note.rotation.z = note._speed, note._rx, note._ry, note._rz
		end
	end
end

return Notefield
