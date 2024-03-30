local Note = ActorSprite:extend("Note")

Note.colors = {"purple", "blue", "green", "red"}
Note.directions = {"left", "down", "up", "right"}
Note.pixelAnim = {{{4}, {0}}, {{5}, {1}}, {{6}, {2}}, {{7}, {3}}}

local safeZoneOffset = (10 / 60) * 1000

function Note.toPos(time, speed)
	return time * 450 * speed
end

function Note:checkDiff(time)
	return self.time > time - safeZoneOffset * self.lateHitMult and
		self.time < time + safeZoneOffset * self.earlyHitMult
end

function Note:new(time, column, sustaintime, noteskin)
	Note.super.new(self)

	self.scale.x, self.scale.y = 0.7, 0.7
	self.time = time

	self.canBeHit, self.wasGoodHit, self.tooLate, self.ignoreNote = true, false, false, false
	self.priority, self.earlyHitMult, self.lateHitMult = 0, 1, 1
	self.showNote, self.showNoteOnHit = true, false
	self.hit = false
	self.type = ""
	self.lane = nil

	self:setNoteskin(noteskin)
	self:setColumn(column)
	self:setSustainTime(sustaintime)

	self:play("static")
end

function Note:setNoteskin(noteskin)
	if noteskin == self.noteskin then return end
	self.noteskin = noteskin

	local col, sus = self.column, self.sustainTime
	self.column, self.sustainTime = nil

	if noteskin == "pixel" then -- ?
		self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'))
		self.width = self.width / 4
		self.height = self.height / 5
		self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'), true, math.floor(self.width), math.floor(self.height))
	else
		self:setFrames(paths.getSparrowAtlas("skins/" .. noteskin .."/NOTE_assets"))
	end

	if col then self:setColumn(col) end
	if sus then self:setSustainTime(sus) end
end

function Note:setColumn(column)
	if column == self.column then return end
	self.column = column

	local color = Note.colors[column + 1]
	self:addAnimByPrefix("static", color .. "0")
end

function Note:setSustainTime(sustaintime)
	if sustaintime == self.sustainTime then return end
	self.sustainTime = sustaintime

	if sustaintime <= 100 then return end
	local column, noteskin = self.column, self.noteskin
	local color = Note.colors[column + 1]

	local sustain, susend = self.sustain or ActorSprite(), self.sustainEnd or ActorSprite()
	self.sustain, self.sustainEnd = sustain, susend

	if noteskin == "pixel" then

	elseif noteskin == "normal" then
		if column == 0 then
			susend:addAnimByPrefix(color .. "holdend", "pruple end hold")
		else
			susend:addAnimByPrefix(color .. "holdend", color .. " hold end")
		end
		sustain:addAnimByPrefix("static", color .. " hold piece")
	else
		susend:addAnimByPrefix("static", color .. " hold end")
		sustain:addAnimByPrefix("static", color .. " hold piece")
	end

	susend:play("static"); self.updateHitbox(susend)
	sustain:play("static"); self.updateHitbox(sustain)
end

function Note:updateHitbox()
	local width, height = self:getFrameDimensions()

	self.width = math.abs(self.scale.x * self.zoom.x) * width
	self.height = math.abs(self.scale.y * self.zoom.y) * height
	self.__width, self.__height = self.width, self.height

	self:centerOrigin(width, height)
	self:centerOffsets(width, height)
end

function Note:play(anim, force, frame)
	Note.super.play(self, anim, force, frame)
	self:updateHitbox()
end

function Note:_canDraw()
	if self.sustain then
		self.sustain.cameras = self.cameras
		self.sustainEnd.cameras = self.cameras
	end
	return (self.texture ~= nil and (self.width ~= 0 or self.height ~= 0)) and
		(Note.super._canDraw(self) or (
			self.sustain and (self.sustain:_canDraw() or self.sustainEnd:_canDraw())
		))
end

function Note:__render(camera)
	if self.sustain then
		
	end
	Note.super.__render(self, camera)
end

--[[
Note.chartingMode = false

function Note:new(time, data, prevNote, sustain, parentNote)
	Note.super.new(self, 0, -2000)

	self.time = time
	self.data = data
	self.prevNote = prevNote
	if sustain == nil then sustain = false end
	self.isSustain, self.isSustainEnd, self.parentNote = sustain, false, parentNote
	self.mustPress = false
	self.canBeHit, self.wasGoodHit, self.tooLate = false, false, false
	self.earlyHitMult, self.lateHitMult = 1, 1
	self.type = ''
	self.ignoreNote = false

	self.scrollOffset = {x = 0, y = 0}

	local color = Note.colors[data + 1]
	if PlayState.pixelStage then
		if sustain then
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assetsENDS'))
			self.width = self.width / 4
			self.height = self.height / 2
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assetsENDS'),
				true, math.floor(self.width),
				math.floor(self.height))

			self:addAnim(color .. 'holdend', Note.pixelAnim[data + 1][1])
			self:addAnim(color .. 'hold', Note.pixelAnim[data + 1][2])
		else
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'))
			self.width = self.width / 4
			self.height = self.height / 5
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'), true,
				math.floor(self.width), math.floor(self.height))

			self:addAnim(color .. 'Scroll', Note.pixelAnim[data + 1][1])
		end

		self:setGraphicSize(math.floor(self.width * 6))
		self.antialiasing = false
	else
		self:setFrames(paths.getSparrowAtlas("skins/normal/NOTE_assets"))

		if sustain then
			if data == 0 then
				self:addAnimByPrefix(color .. "holdend", "pruple end hold")
			else
				self:addAnimByPrefix(color .. "holdend", color .. " hold end")
			end
			self:addAnimByPrefix(color .. "hold", color .. " hold piece")
		else
			self:addAnimByPrefix(color .. "Scroll", color .. "0")
		end

		self:setGraphicSize(math.floor(self.width * 0.7))
	end
	self:updateHitbox()

	self:play(color .. "Scroll")

	if sustain and prevNote then
		table.insert(parentNote.children, self)

		self.alpha = 0.6
		self.earlyHitMult = 0.5
		self.scrollOffset.x = self.scrollOffset.x + self.width / 2

		self:play(color .. "holdend")
		self.isSustainEnd = true

		self:updateHitbox()

		self.scrollOffset.x = self.scrollOffset.x - self.width / 2

		if PlayState.pixelStage then
			self.scrollOffset.x = self.scrollOffset.x + 30
		end

		if prevNote.isSustain then
			prevNote:play(Note.colors[prevNote.data + 1] .. "hold")
			prevNote.isSustainEnd = false

			prevNote.scale.y = (prevNote.width / prevNote:getFrameWidth()) *
				((PlayState.conductor.stepCrotchet / 100) *
					(1.05 / 0.7)) * PlayState.SONG.speed

			if PlayState.pixelStage then
				prevNote.scale.y = prevNote.scale.y * 5
				prevNote.scale.y = prevNote.scale.y * (6 / self.height)
			end
			prevNote:updateHitbox()
		end
	else
		self.children = {}
	end
end

local safeZoneOffset = (10 / 60) * 1000

function Note:checkDiff()
	local instTime =
		(Note.chartingMode and ChartingState or PlayState).conductor.time
	return self.time > instTime - safeZoneOffset * self.lateHitMult and
		self.time < instTime + safeZoneOffset * self.earlyHitMult
end

function Note:update(dt)
	local instTime =
		(Note.chartingMode and ChartingState or PlayState).conductor.time
	self.canBeHit = self:checkDiff()

	if self.mustPress then
		if not self.ignoreNote and not self.wasGoodHit and
			self.time < instTime - safeZoneOffset then
			self.tooLate = true
		end
	end

	if self.tooLate and self.alpha > 0.3 then self.alpha = 0.3 end

	Note.super.update(self, dt)
end]]

return Note