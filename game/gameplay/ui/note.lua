local Note = Sprite:extend()

Note.swagWidth = 160 * 0.7
Note.colors = { "purple", "blue", "green", "red" }
Note.directions = { "left", "down", "up", "right" }

function Note:new(time, data, prevNote, sustain)
	Note.super.new(self, 0, -2000)
	self:setFrames(paths.getSparrowFrames("skins/normal/NOTE_assets"))

	self.time = time
	self.data = data
	self.prevNote = prevNote
	if sustain == nil then sustain = false end
	self.isSustain, self.isSustainEnd, self.isSustainEnd, self.sustainLength =
	sustain, false, false, 0
	self.parentNote, self.childNotes = nil, nil
	self.mustPress = false
	self.canBeHit, self.wasGoodHit, self.tooLate, self.hasMissed = false, false,
		false, false
	self.earlyHitMult, self.lateHitMult = 1, 1
	self.altNote = false

	self.scrollOffset = { x = 0, y = 0 }

	local color = Note.colors[data + 1]
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
	self:updateHitbox()

	self:play(color .. "Scroll")

	if sustain and prevNote then
		self.alpha = 0.6
		self.earlyHitMult = 0.5
		self.scrollOffset.x = self.scrollOffset.x + self.width / 2

		self:play(color .. "holdend")
		self.isSustainEnd = true

		self:updateHitbox()

		self.scrollOffset.x = self.scrollOffset.x - self.width / 2

		self.parentNote = prevNote
		while self.parentNote.isSustain and self.parentNote.prevNote do
			self.parentNote = self.parentNote.prevNote
		end

		if prevNote.isSustain then
			table.insert(self.parentNote.childNotes, self)

			prevNote:play(Note.colors[prevNote.data + 1] .. "hold")
			prevNote.isSustainEnd = false

			prevNote.scale.y = (prevNote.width / prevNote:getFrameWidth()) * ((music.stepCrochet / 100) * (1.05 / 0.7)) *
				PlayState.song.speed
			prevNote:updateHitbox()
			prevNote.scale.y = prevNote.scale.y + 1 / prevNote:getFrameHeight()
		end
	else
		self.childNotes = {}
	end
end

local safeZoneOffset = (10 / 60) * 1000

function Note:checkDiff()
	return self.time > PlayState.songPosition - safeZoneOffset * self.lateHitMult and
		self.time < PlayState.songPosition + safeZoneOffset * self.earlyHitMult
end

function Note:update(dt)
	self.canBeHit = self:checkDiff()

	if self.mustPress then
		if not self.wasGoodHit and self.time < PlayState.songPosition - safeZoneOffset then
			self.tooLate = true
		end
	end

	if self.tooLate and self.alpha > 0.3 then self.alpha = 0.3 end

	Note.super.update(self, dt)
end

return Note
