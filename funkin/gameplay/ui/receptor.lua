local Receptor = Sprite:extend('Receptor')

function Receptor:new(x, y, data, player)
	Receptor.super.new(self, x, y)

	self.data = data
	self.player = player
	self.holdTime = 0

	self.__shaderTable = {}

	self.__style = 'unknown'
	self:setStyle(PlayState.SONG.noteStyle or
		(PlayState.pixelStage and 'pixel' or 'default'))
end

function Receptor:_addAnim(...)
	local args = {...}
	if type(args[2]) == 'table' then
		self:addAnim(...)
	else
		self:addAnimByPrefix(...)
	end
end

function Receptor:setStyle(style)
	if style == self.__style then return end

	self.__shaderTable = {}
	if paths.getJSON('data/notes/' .. style) == nil then
		print("Note Style with name " .. style .. " doesn't exists!")
		style = self.__style
	end
	self.__style = style

	local json = paths.getJSON('data/notes/' .. style)
	local jsonData = json.receptors
	local texture, str = '', 'skins/%s/%s'
	texture = str:format(jsonData.isPixel and 'pixel' or 'normal',
		jsonData.sprite)

	if jsonData.isPixel then
		self:loadTexture(paths.getImage(texture), true,
			jsonData.frameWidth, jsonData.frameHeight)
	else
		self:setFrames(paths.getAtlas(texture))
	end

	for _, anim in ipairs(jsonData.animations) do
		self:_addAnim(anim[1], anim[2], anim[3], anim[4])
	end

	local idx = math.min(self.data + 1, #jsonData.colors)
	self.__shaderTable['static'] = RGBShader.create(
		Color.fromString(jsonData.colors[idx][1]),
		Color.fromString(jsonData.colors[idx][2]),
		Color.fromString(jsonData.colors[idx][3])
	)
	local noteColor = json.notes.colors
	idx = math.min(self.data + 1, #noteColor)
	self.__shaderTable['pressed'] = RGBShader.create(
		Color.fromString(noteColor[idx][1]),
		Color.fromString(noteColor[idx][2]),
		Color.fromString(noteColor[idx][3])
	)

	if jsonData.properties then
		local noteProps = jsonData.properties[self.data + 1]
		for prop, val in pairs(noteProps) do
			self[prop] = val
		end
	end

	self.antialiasing = jsonData.antialiasing
	if self.antialiasing == nil then self.antialiasing = true end
	self:setGraphicSize(math.floor(self.width * (jsonData.scale or 0.7)))
	self:updateHitbox()

	self:play('static')
end

function Receptor:update(dt)
	if self.holdTime > 0 then
		self.holdTime = self.holdTime - dt
		if self.holdTime <= 0 then
			self.holdTime = 0
			self:play('static')
		end
	end

	Receptor.super.update(self, dt)
end

function Receptor:play(anim, force, frame)
	local toplay, _anim = anim .. '-note' .. tostring(self.data), self.__animations
	local realAnim = (_anim[toplay] ~= nil) and toplay or anim
	Receptor.super.play(self, realAnim, force, frame)

	self:centerOffsets()
	self:centerOrigin()

	if self.curAnim.name:find('static') then
		self.shader = self.__shaderTable.static
	else
		self.shader = self.__shaderTable.pressed
	end
end

return Receptor
