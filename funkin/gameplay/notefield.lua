local Notefield = ActorGroup:extend("Notefield")

function Notefield:new(x, y, keys, skin, character, vocals, speed)
	if keys == nil then
		keys = 4
	end
	if skin == nil then
		skin = "default"
	end
	if speed == nil then
		speed = 1
	end

	Notefield.super.new(self, x, y)

	self.noteWidth = 160 * 0.7
	self.height = 514
	self.keys = keys
	self.skin = paths.getSkin(skin)

	self.time, self.beat = 0, 0
	self.offsetTime = 0
	self.speed = speed
	self.drawSize = game.height * 2 + self.noteWidth
	self.drawSizeOffset = 0
	self.downscroll = false -- this just sets scale y backwards
	self.canSpawnSplash = true

	-- for PlayState
	self.character, self.vocals = character, vocals
	self.bot = false
	self.lastSustain = nil
	self.recentPresses = {}

	self.modifiers = {}

	self.lanes = {}
	self.receptors = {}
	self.notes = {}

	self.__topSprites = Group()
	self.__offsetX = -self.noteWidth / 2 - (self.noteWidth * keys / 2)
	for i = 1, keys do self:makeLane(i).x = self.__offsetX + self.noteWidth * i end
	self.__offsetX = self.__offsetX / (1 + 1 / keys)
	self:add(self.__topSprites)

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
	self.__topSprites:add(lane.receptor.covers)
	self.__topSprites:add(lane.receptor.splashes)
	return lane
end

function Notefield:addNote(note)
	note.parent = self
	table.insert(self.notes, note)
	return note
end

function Notefield:makeNote(time, column, sustain, type, skin)
	local note = Note(time, column, sustain, type, skin or self.skin)
	self:addNote(note)
	return note
end

function Notefield:makeNotesFromChart(notes)
	local gf = game:getState().gf
	if gf and not gf:is(Character) then
		gf = nil
	end
	for _, n in ipairs(notes) do
		if n.t >= PlayState.startPos then
			local sustainTime = n.l or 0
			if sustainTime ~= 0 then
				sustainTime = math.max(sustainTime / 1000, 0.125)
			end
			local note = self:makeNote(n.t / 1000, n.d % 4, sustainTime, n.k)
			-- do not ask why i didn't add a callback. -stilic
			if gf and n.gf then note.character = gf end
		end
	end
end

function Notefield:copyNotesFromNotefield(notefield)
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

function Notefield:removeNoteFromIndex(idx)
	local note = self.notes[idx]
	if not note then return end
	if self.lastSustain == note then
		self.lastSustain = nil
	end
	note.lastPress = nil

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
		return self:removeNoteFromIndex(idx)
	end
end

function Notefield:setSkin(skin)
	if self.skin.skin == skin then return end

	skin = skin and paths.getSkin(skin) or paths.getSkin("default")
	self.skin = skin

	for _, receptor in ipairs(self.receptors) do
		receptor:setSkin(skin)
	end
	for _, note in ipairs(self.notes) do
		note:setSkin(skin)
	end
end

function Notefield:fadeInReceptors()
	for i = 1, #self.lanes do
		local receptor = self.lanes[i].receptor
		receptor.y = receptor.y - 10
		receptor.alpha = 0

		Tween.tween(receptor, {y = receptor.y + 10, alpha = 1}, 1, {
			ease = "circOut",
			startDelay = 0.16 + (0.2 * i)
		})
	end
end

function Notefield:getNotes(time, direction, sustainLoop)
	local notes = self.notes
	if #notes == 0 then return {} end

	local safeZoneOffset, hitNotes, i, started, hasSustain,
	forceHit, noteTime, hitTime, prev, prevIdx = Note.safeZoneOffset, {}, 1
	for _, note in ipairs(notes) do
		noteTime = note.time
		if not note.tooLate
			and not note.ignoreNote
			and (direction == nil or note.direction == direction)
			and (note.lastPress
				or (noteTime > time - safeZoneOffset * note.lateHitMult
					and noteTime < time + safeZoneOffset * note.earlyHitMult)) then
			forceHit = sustainLoop and not note.wasGoodSustainHit and note.sustain
			if forceHit then hasSustain = true end
			if not note.wasGoodHit or forceHit then
				prevIdx = i - 1
				prev = hitNotes[prevIdx]
				if prev and noteTime - prev.time <= 0.001 and note.sustainTime > prev.sustainTime then
					hitNotes[i] = prev
					hitNotes[prevIdx] = note
				else
					hitNotes[i] = note
				end
				i = i + 1
				started = true
			elseif started then
				break
			end
		end
	end

	return hitNotes, hasSustain
end

function Notefield:update(dt)
	Notefield.super.update(self, dt)
	for _, lane in ipairs(self.lanes) do
		for _, note in ipairs(lane.renderedNotes) do
			note:update(dt)
		end
	end
	for _, mod in pairs(self.modifiers) do mod:update(self.beat) end
end

function Notefield:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.width) / 2 end
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
	self.x = self.x - self.__offsetX
	Notefield.super.__render(self, camera)
	self.x = self.x + self.__offsetX
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
