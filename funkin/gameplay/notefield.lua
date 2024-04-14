local Notefield = ActorGroup:extend("Notefield")

-- reset on Playstate enter
Notefield.safeZoneOffset = 10 / 60
Notefield.sustainSafeZone = 1 / 2 -- not implemented yet

function Notefield.resetRating()
	Notefield.ratings = {
		{name = "perfect", time = 0.026, score = 400, splash = true,  mod = 1.0},
		{name = "sick",    time = 0.038, score = 350, splash = true,  mod = 0.98},
		{name = "good",    time = 0.096, score = 200, splash = false, mod = 0.7},
		{name = "bad",     time = 0.138, score = 100, splash = false, mod = 0.4},
		{name = "shit",    time = -1,    score = 50,  splash = false, mod = 0.2}
	}
end

Notefield.resetRating()

function Notefield.getRating(a, b, returnShit)
	local diff = math.abs(a - b)
	for i, r in ipairs(Notefield.ratings) do
		if diff <= (r.time < 0 and Notefield.safeZoneOffset or r.time) then return r, i end
	end
	return returnShit and Notefield.ratings[#Notefield.ratings] or nil
end

function Notefield.checkDiff(note, time)
	return note.time > time - Notefield.safeZoneOffset * note.lateHitMult and
		note.time < time + Notefield.safeZoneOffset * note.earlyHitMult
end

function Notefield.getScoreSustain(time, note)
	return math.min(time - note.time + Notefield.safeZoneOffset, note.sustainTime) * 1000
end

function Notefield:new(x, y, keys, skin, character, vocals)
	Notefield.super.new(self, x, y)

	self.noteWidth = math.floor(160 * 0.7)
	self.height = 500
	self.keys = keys
	self.skin = skin and paths.getNoteskin(skin) or paths.getNoteskin("default")
	self.character, self.vocals = character, vocals

	self.hitsoundVolume, self.hitsound = 0, paths.getSound("hitsound")
	self.ghostTap = ClientPrefs.data.ghostTap or false
	self.canSpawnSplash, self.bot = true, false
	self.vocalVolume = 1

	self.downscroll = false -- this just sets scale y backwards
	self.time, self.beat = 0, 0
	self.offsetTime = 0
	self.speed = 1
	self.drawSize = game.height + self.noteWidth
	self.drawSizeOffset = 0

	self.totalPlayed = 0
	self.totalHit = 0.0
	self.score = 0
	self.misses = 0
	self.perfects = 0
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0

	self.modifiers = {}

	self.lastPress = {}
	self.pressed = {}
	self.lanes = {}
	self.receptors = {}
	self.hitNotes = {}
	self.missedNotes = {}
	self.notes = {}
	self.splashes = {}

	local startx = -self.noteWidth / 2 - (self.noteWidth * keys / 2)
	for i = 1, keys do
		self:makeLane(i).x = startx + self.noteWidth * i
	end

	self:getWidth()
end

function Notefield:enter(parent)
	self.parent = parent
	self.canHitCallbacks = parent.miss ~= nil and parent.goodNoteHit ~= nil and parent.goodHoldHit ~= nil
end

function Notefield:leave()
	self.parent, self.canHitCallbacks = nil
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
	self.pressed[direction] = false
	self.lastPress[direction] = 0
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

function Notefield:removeNotefromIndex(idx, dontClearHits)
	local note = self.notes[idx]
	if not note then return end
	if not dontClearHits then
		table.delete(self.missedNotes, note)
		table.delete(self.hitNotes, note)
		note.parent = nil
	end

	local lane = note.group
	if lane then
		note.group, lane.renderedNotesI[note] = nil
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

function Notefield:getNotes(time, direction)
	local gotNotes, notes = {}, self.notes
	local i, size = 1, #notes
	if size == 0 then return gotNotes end

	local offset = time - Notefield.safeZoneOffset
	while i < size and offset >= notes[i + 1].time do i = i + 1 end
	while i > 1 and offset < notes[i - 1].time do i = i - 1 end
	while i <= size do
		local n = notes[i]
		local dont = n.tooLate or n.wasGoodHit
		if (n.lastPress or n.time) > time and not Notefield.checkDiff(n, time) and not dont then break end
		if not dont and n.direction == direction then
			table.insert(gotNotes, n)
		end
		i = i + 1
	end

	return gotNotes
end

function Notefield:hit(time, note, force)
	local sus = note.sustain and note.hit
	local notetime = sus and note.time + note.sustainTime or note.time
	local rating = Notefield.getRating(notetime, sus and math.min(time, notetime) or time)
	if not rating and not sus then return self:missNote(note, force) end
	note.pressed = true
	note.lastPress = time

	if force or not note.sustain then
		self:removeNote(note, true)
		note.wasGoodHit = true
	end

	if not note.hit then
		table.insert(self.hitNotes, note)
		note.hit = true

		local name = rating.name .. "s"
		self.totalPlayed, self.totalHit = self.totalPlayed + 1, self.totalHit + rating.mod
		self[name], self.score = (self[name] or 0) + 1, self.score + rating.score

		if self.canHitCallbacks then
			self.parent:goodNoteHit(self, note, rating.score, rating)
		end
	elseif note.sustain then -- for sustains
		if not rating then return end
		local addScore = Notefield.getScoreSustain(time, note)
		self.totalPlayed, self.totalHit = self.totalPlayed + 1, self.totalHit + rating.mod
		self.score = self.score + addScore

		if self.canHitCallbacks then
			self.parent:goodHoldHit(self, note, addScore, rating)
		end
	end

	return rating
end

function Notefield:miss(direction, note)
	local addScore = -100
	self.totalPlayed, self.misses = self.totalPlayed + 1, self.misses + 1
	self.score = self.score + addScore

	if self.canHitCallbacks then
		self.parent:miss(self, direction, addScore, note)
	end
end

function Notefield:missNote(note, force, play)
	if force or not note.sustain then
		self:removeNote(note, true)
	end

	if not note.tooLate then
		table.insert(self.missedNotes, note)
		note.tooLate = true

		if not note.ignoreNote then
			self:miss(note.direction, note, play)
		end
	end
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

function Notefield:press(time, direction, play)
	time = time or self.time

	local fixedDirection, gotNotes = direction + 1, self:getNotes(time, direction)
	local missed = #gotNotes == 0

	if self.pressed[fixedDirection] then
		self:release(time, direction, false)
	end

	self.lastPress[fixedDirection] = time
	self.pressed[fixedDirection] = true
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
		self.pressed[fixedDirection] = coolNote
		if coolNote.sustain and coolNote.wasGoodHit then
			rating = nil
		end

		if play and self.hitsoundVolume > 0 and self.hitsound then
			game.sound.play(self.hitsound, self.hitsoundVolume)
		end
	elseif not self.ghostTap then
		self:miss(direction, nil, play)
	end

	if play then
		local receptor = self.receptors[fixedDirection]
		if receptor then
			receptor:play(missed and "pressed" or "confirm", true)
			if not missed and isSustain then receptor.strokeTime = -1 end
			if rating and rating.splash then self:spawnSplash(direction) end
		end

		local char = self.character
		if char and (not missed or not self.ghostTap) then
			char:sing(direction, missed and "missed" or nil)
			if not missed and isSustain then char.strokeTime = -1 end
		end
	end

	return not missed, rating, gotNotes
end

function Notefield:release(time, direction, play)
	local fixedDirection = direction + 1
	local note = self.pressed[fixedDirection]
	self.pressed[fixedDirection] = nil
	if not note then return end

	local hit, rating = note ~= true
	time = time or self.time
	if hit then
		if note.sustain and note.hit then
			rating = self:hit(time, note, time - note.time + Notefield.safeZoneOffset > note.sustainTime)
		end
		note.pressed = nil
		note.lastPress = time
	end

	if play then
		local receptor = self.receptors[fixedDirection]
		if receptor then
			receptor:play("static", true)
		end

		if hit then
			local char = self.character
			if char and char.dirAnim == direction then
				char.strokeTime = 0
			end
		end
	end

	return hit, rating, hit and note or nil
end

function Notefield:update(dt)
	Notefield.super.update(self, dt)

	local time = self.time
	for i, note in pairs(self.pressed) do
		if note ~= true and note and note.sustain and time > note.time + note.sustainTime then
			local receptor = self.receptors[note.direction + 1]
			if receptor then
				receptor.strokeTime = 0
			end

			local char = self.character
			if char and char.dirAnim == note.direction then
				char.strokeTime = 0
			end
		end
	end

	for i = #self.splashes, 1, -1 do
		local splash = self.splashes[i]
		if splash.animFinished then
			table.remove(self.splashes, i)
			self:remove(splash)
		end
	end

	for _, mod in pairs(self.modifiers) do mod:update(self.beat) end

	-- this looks shit please rewrite this
	local notes = self.notes
	local offset, i = time - Notefield.safeZoneOffset, 1
	while i <= #notes do
		local note = notes[i]
		if offset <= note.time then break end

		if not note.hit and not note.tooLate then
			self:missNote(note)
		elseif not note.pressed and note.sustain and time - Notefield.sustainSafeZone > (note.lastPress or note.time) then
			local yeah = time + Notefield.safeZoneOffset > note.time + note.sustainTime
			if not note.tooLate and note.hit and yeah then
				self:hit(time, note, true)
			else
				self:missNote(note, yeah)
			end
			if not yeah then
				i = i + 1
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
