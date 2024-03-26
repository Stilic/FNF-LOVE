local Receptor = Sprite:extend('Receptor')

function Receptor:new(x, y, data, player)
	Receptor.super.new(self, x, y)
	local style = PlayState.SONG.noteStyle or (PlayState.pixelStage and 'pixel' or 'default')

	self.data = data
	self.player = player
	self.holdTime = 0

	self:setStyle(self, style)
end

function Receptor:setStyle(data, style)
	local json = paths.getJSON('data/notes/' .. style)

	local repData = json.receptors[data.data + 1]
	local function setShader(anim, color)
		if json.noShader then return end
		anim.shader = RGBShader.create(
			Color.fromString(color[1]),
			Color.fromString(color[2]),
			Color.fromString(color[3]))
	end

	if json.isPixel then
		local texture = 'skins/pixel/' .. json.texture
		data:loadTexture(paths.getImage(texture))

		data.width = data.width / json.columnsNote
		data.height = data.height / json.rowsNote
		data:loadTexture(paths.getImage(texture), true, math.floor(data.width), math.floor(data.height))

		data:addAnim('static', repData.staticAnim)
		data:addAnim('pressed', repData.pressedAnim, 12, false)
		data:addAnim('confirm', repData.hitAnim, 24, false)

		setShader(data.__animations['static'], repData.color)
		setShader(data.__animations['pressed'], repData.pressedColor and
				repData.pressedColor or json.notes[data.data + 1].color)
		setShader(data.__animations['confirm'], repData.hitColor and
				repData.hitColor or json.notes[data.data + 1].color)
	else
		local texture = 'skins/normal/' .. json.texture
		data:setFrames(paths.getAtlas(texture))
		data:setGraphicSize(math.floor(data.width * 0.7))

		data:addAnimByPrefix('static', repData.staticAnim, 24, false)
		data:addAnimByPrefix('pressed', repData.pressedAnim, 24, false)
		data:addAnimByPrefix('confirm', repData.hitAnim, 24, false)

		setShader(data.__animations['static'], repData.color)
		setShader(data.__animations['pressed'], repData.pressedColor and
				repData.pressedColor or json.notes[data.data + 1].color)
		setShader(data.__animations['confirm'], repData.hitColor and
				repData.hitColor or json.notes[data.data + 1].color)
	end
	if repData.props then
		for prop, val in pairs(repData.props) do
			data[prop] = val
		end
	end

	data.antialiasing = json.antialiasing
	if data.antialiasing == nil then data.antialiasing = true end
	data:setGraphicSize(math.floor(data.width * (json.scale or 0.7)))
	data:updateHitbox()

	data:play('static')
end

function Receptor:update(dt)
	if self.holdTime > 0 then
		self.holdTime = self.holdTime - dt
		if self.holdTime <= 0 then
			self.holdTime = 0
			self:play("static")
		end
	end

	Receptor.super.update(self, dt)
end

function Receptor:play(anim, force, frame)
	Receptor.super.play(self, anim, force, frame)

	self:centerOffsets()
	self:centerOrigin()
	self.shader = self.curAnim.shader
end

return Receptor
