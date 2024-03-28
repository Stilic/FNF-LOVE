local Note = Sprite:extend('Note')
Note.chartingMode = false
Note.swagWidth = 160 * 0.7
Note.directions = {'left', 'down', 'up', 'right'}

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

	self.__style = 'unknown'
	self:setStyle(PlayState.SONG.noteStyle or
		(PlayState.pixelStage and 'pixel' or 'default'))
end

function Note:_addAnim(...)
	local args = {...}
	if type(args[2]) == 'table' then
		self:addAnim(...)
	else
		self:addAnimByPrefix(...)
	end
end

function Note:setStyle(style)
	if style == self.__style then return end

	if paths.getJSON('data/notes/' .. style) == nil then
		print("Note Style with name " .. style .. " doesn't exists!")
		style = self.__style
	end
	self.__style = style

	local jsonData = paths.getJSON('data/notes/' .. style).notes
	local texture, str = '', 'skins/%s/%s'
	texture = str:format(jsonData.isPixel and 'pixel' or 'normal',
		jsonData.sprite)

	if jsonData.isPixel then
		if self.isSustain then
			local holdData = jsonData.sustains
			self:loadTexture(paths.getImage(texture .. 'ENDS'), true,
				holdData.frameWidth, holdData.frameHeight)
		else
			self:loadTexture(paths.getImage(texture), true,
				jsonData.frameWidth, jsonData.frameHeight)
		end
	else
		self:setFrames(paths.getAtlas(texture))
	end

	local animData = self.isSustain and jsonData.sustains or jsonData
	for _, anim in ipairs(animData.animations) do
		self:_addAnim(anim[1], anim[2], anim[3], anim[4])
	end

	if animData.properties then
		local noteProps = animData.properties[self.data + 1]
		for prop, val in pairs(noteProps) do
			self[prop] = val
		end
	end

	if not jsonData.disableRgb then
		local idx = math.min(self.data + 1, #jsonData.colors)
		self.shader = RGBShader.create(
			Color.fromString(jsonData.colors[idx][1]),
			Color.fromString(jsonData.colors[idx][2]),
			Color.fromString(jsonData.colors[idx][3])
		)
	end

	self.antialiasing = jsonData.antialiasing
	if self.antialiasing == nil then self.antialiasing = true end
	self:setGraphicSize(math.floor(self.width * (jsonData.scale or 0.7)))
	self:updateHitbox()

	self:play('note')

	if self.isSustain and self.prevNote then
		table.insert(self.parentNote.children, self)

		self.alpha = 0.6
		self.earlyHitMult = 0.5
		self.scrollOffset.x = self.width / 2

		self:play('endhold')
		self.isSustainEnd = true

		self:updateHitbox()

		self.scrollOffset.x = self.scrollOffset.x - self.width / 2

		if jsonData.isPixel then
			self.scrollOffset.x = self.scrollOffset.x + 30
		end

		if self.prevNote.isSustain then
			self.prevNote:play('hold')
			self.prevNote.isSustainEnd = false

			self.prevNote.scale.y = (self.prevNote.width / self.prevNote:getFrameWidth()) *
				((PlayState.conductor.stepCrotchet / 100) *
					(1.05 / 0.7)) * PlayState.SONG.speed

			if jsonData.isPixel then
				self.prevNote.scale.y = self.prevNote.scale.y * 5
				self.prevNote.scale.y = self.prevNote.scale.y * (6 / self.height)
			end
			self.prevNote:updateHitbox()
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

function Note:play(anim, force, frame)
	local toplay, _anim = anim .. '-note' .. tostring(self.data), self.__animations
	local realAnim = (_anim[toplay] ~= nil) and toplay or anim
	Note.super.play(self, realAnim, force, frame)
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
end

return Note
