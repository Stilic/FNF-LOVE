local NoteSplash = Sprite:extend("NoteSplash")

function NoteSplash:new(x, y)
	NoteSplash.super.new(self, x, y)
	self.__shaderTable = {}
	self.__data = 0

	self.__style = "unknown"
	self:setStyle(PlayState.SONG.noteStyle or
		(PlayState.pixelStage and "pixel" or "default"))
end

function NoteSplash:setStyle(style)
	if style == self.__style then return end

	if paths.getJSON("data/notes/" .. style) == nil then
		print("Note Style with name " .. style .. " doesn't exists!")
		style = self.__style
	end
	self.__style = style

	local jsonData = paths.getJSON("data/notes/" .. style).splashes
	local texture, str = "", 'skins/%s/%s'
	texture = str:format(jsonData.isPixel and 'pixel' or 'normal',
		jsonData.sprite)
	self:setFrames(paths.getAtlas(texture))

	local function setShader(anim, color)
		if json.disableRgb then return end
		anim.shader = RGBShader.create(
			Color.fromString(color[1]),
			Color.fromString(color[2]),
			Color.fromString(color[3]))
	end

	local colorData = jsonData.colors and jsonData.colors or
		paths.getJSON("data/notes/" .. style).notes.colors

	for i = 1, #colorData do
		self.__shaderTable["splash" .. i] = RGBShader.create(
			Color.fromString(colorData[i][1]),
			Color.fromString(colorData[i][2]),
			Color.fromString(colorData[i][3])
		)
	end

	self.animationData = jsonData.animations
	for _, anim in ipairs(self.animationData) do
		self:addAnimByPrefix(anim[1], anim[2], anim[3], anim[4])
	end

	self.antialiasing = jsonData.antialiasing
	if self.antialiasing == nil then self.antialiasing = true end
	self:setGraphicSize(math.floor(self.width * (jsonData.scale or 0.7)))
	self:updateHitbox()
end

function NoteSplash:setup(data)
	self.__data = data
	self.alpha = 0.6

	self:play("splash" .. tostring(math.random(0, 1)), true)

	self.curAnim.framerate = 24 + math.random(-2, 2)
	self:updateHitbox()

	self.shader = self.__shaderTable["splash" .. data + 1]

	self.offset.x, self.offset.y = self.width * 0.3, self.height * 0.3
end

function NoteSplash:play(anim, force, frame)
	local toplay, _anim = anim .. "-note" .. tostring(self.__data), self.__animations
	local realAnim = (_anim[toplay] ~= nil) and toplay or anim
	NoteSplash.super.play(self, realAnim, force, frame)
end

function NoteSplash:update(dt)
	if self.alive and self.animFinished then self:kill() end

	NoteSplash.super.update(self, dt)
end

return NoteSplash
