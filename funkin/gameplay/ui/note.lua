local Note = Sprite:extend("Note")

Note.swagWidth = 160 * 0.7
Note.colors = {"purple", "blue", "green", "red"}
Note.directions = {"left", "down", "up", "right"}

Note.chartingMode = false

function Note:new(time, data, prevNote, sustain, parentNote)
	Note.super.new(self, 0, -2000)
	local style = PlayState.SONG.noteStyle or
			(PlayState.pixelStage and "pixel" or "default")

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
	self:setStyle(self, style)
end

function Note:setStyle(data, style)
	self.scrollOffset = {x = 0, y = 0}
	local json = paths.getJSON("data/notes/" .. style)
	local noteData = json.notes[data.data + 1]
	if json.isPixel then
		local img = 'skins/pixel/' .. json.texture
		if data.isSustain then
			data:loadTexture(paths.getImage(img .. json.sustainSuffix))
			data.width = data.width / json.columnsSustain
			data.height = data.height / json.rowsSustain
			data:loadTexture(paths.getImage(img .. json.sustainSuffix),
				true, math.floor(data.width),
				math.floor(data.height))

			data:addAnim('holdend', noteData.sustainAnims[1])
			data:addAnim('hold', noteData.sustainAnims[2])
		else
			data:loadTexture(paths.getImage(img))
			data.width = data.width / json.columnsNote
			data.height = data.height / json.rowsNote
			data:loadTexture(paths.getImage(img), true,
				math.floor(data.width), math.floor(data.height))

			data:addAnim('note', noteData.anim)
			if noteData.props then
				for prop, val in pairs(noteData.props) do
					data[prop] = val
				end
			end
		end
	else
		local texture = "normal/" .. json.texture
		data:setFrames(paths.getAtlas("skins/" .. texture))

		if data.isSustain then
			data:addAnimByPrefix("hold", noteData.sustainAnims[1])
			data:addAnimByPrefix("holdend", noteData.sustainAnims[2])
		else
			data:addAnimByPrefix("note", noteData.anim)
			if noteData.props then
				for prop, val in pairs(noteData.props) do
					data[prop] = val
				end
			end
		end
	end
	if not json.noShader then
		data.shader = RGBShader.create(
			Color.fromString(noteData.color[1]),
			Color.fromString(noteData.color[2]),
			Color.fromString(noteData.color[3])
		)
	end

	data.antialiasing = (json.antialiasing ~= nil and json.antialiasing or true)
	data:setGraphicSize(math.floor(data.width * (json.scale or 0.7)))
	data:updateHitbox()

	data:play("note")

	if data.isSustain and data.prevNote then
		table.insert(data.parentNote.children, data)

		data.alpha = 0.6
		data.earlyHitMult = 0.5
		data.scrollOffset.x = data.width / 2

		data:play("holdend")
		data.isSustainEnd = true

		data:updateHitbox()

		data.scrollOffset.x = data.scrollOffset.x - data.width / 2

		if json.isPixel then
			data.scrollOffset.x = data.scrollOffset.x + 30
		end

		if data.prevNote.isSustain then
			data.prevNote:play("hold")
			data.prevNote.isSustainEnd = false

			data.prevNote.scale.y = (data.prevNote.width / data.prevNote:getFrameWidth()) *
				((PlayState.conductor.stepCrotchet / 100) *
					(1.05 / 0.7)) * PlayState.SONG.speed

			if json.isPixel then
				data.prevNote.scale.y = data.prevNote.scale.y * 5
				data.prevNote.scale.y = data.prevNote.scale.y * (6 / data.height)
			end
			data.prevNote:updateHitbox()
		end
	else
		data.children = {}
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
end

return Note
