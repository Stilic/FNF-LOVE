local AtlasText = SpriteGroup:extend("AtlasText")
local AtlasChar = require "funkin.ui.atlastext.atlaschar"

AtlasText.defaultFont = paths.getJSON("data/fonts/default")
AtlasText.tabSize = 2
AtlasText.lineSize = 86
AtlasText.spaceWidth = 28

function AtlasText.getFont(font, size)
	font = font or "default"
	font = paths.getJSON("data/fonts/" .. font)
	if font == nil then font = AtlasText.defaultFont end
	if size ~= nil then font.scale = size end
	font.scale = font.scale or 1
	font.lineSize = font.lineSize or AtlasText.lineSize
	font.spaceWidth = font.spaceWidth or AtlasText.spaceWidth
	return font
end

function AtlasText:new(x, y, text, font, limit, align)
	AtlasText.super.new(self, x or 0, y or 0)

	self.text = text or ""
	self.limit = limit or 0
	self.align = align or "left"

	self.__lines = {}
	self.__batch = love.graphics.newSpriteBatch(Sprite.defaultTexture)

	self:setTyping(0)
	self:setFont(font)
end

function AtlasText:setTyping(speed, sound)
	self.typed = speed > 0
	self.__target, self.timer, self.index = self.text, 0, 0
	self.sound, self.speed, self.completeCallback = sound, speed, nil
	if self.typed then self.text = "" end
end

function AtlasText:setFont(font, size)
	if (font and self.font == font) and (size and self.size == size) then
		return
	end
	self.font = type(font) == "string" and
		AtlasText.getFont(font, size) or font

	self.imageData = paths.getSparrowAtlas('fonts/' .. self.font.name)
	self.__batch:setTexture(self.imageData.texture)

	self:setText()
end

function AtlasText:getCharWidth(char)
	if char == " " or char == "	" then
		return (self.font.spaceWidth * (char == "	" and
			AtlasText.tabSize or 1)) * self.font.scale
	elseif char ~= "\n" then
		local obj = AtlasChar(0, 0, self.font, self.imageData, char)
		local w = obj.width; obj:destroy()
		return w
	end
	return 0
end

function AtlasText:setText(text)
	self:__clear()
	if text ~= nil then self.text = text end

	local line, width = "", 0
	for _, char in ipairs(self.text:split()) do
		local cWidth = self:getCharWidth(char)
		if char == "\n" or (self.limit > 0 and width + cWidth >= self.limit) then
			table.insert(self.__lines, {t = line, w = width})
			line = char == "\n" and "" or char
			width = char == "\n" and 0 or cWidth
		else
			line = line .. char
			width = width + cWidth
		end
	end

	if #line > 0 then table.insert(self.__lines, {t = line, w = width}) end

	for i, curLine in ipairs(self.__lines) do
		local x, xOff = 0, 0
		if self.align ~= "left" then
			xOff = (self.limit - curLine.w) / (self.align == "center" and 2 or 1)
		end
		local y = (i - 1) * (self.font.lineSize * self.font.scale)

		for _, char in ipairs(curLine.t:split()) do
			local letter = self:__makeChar(x + xOff, y, char)
			x = x + letter.width
			if letter.is then self:add(letter) end
		end
	end

	self:updateHitbox()
end

function AtlasText:update(dt)
	if self.typed and not self.finished then
		self.timer = self.timer + dt
		if self.timer >= self.speed then
			self:addLetter()
		end

		if self.index == #self.__target then
			self.finished = true
			if self.completeCallback then self.completeCallback() end
		end
	end

	AtlasText.super.update(self, dt)
end

function AtlasText:forceEnd()
	if not self.typed then return end

	self.text = self.__target
	self.finished = true
	if self.completeCallback then self.completeCallback() end
	self:setText()
end

function AtlasText:addLetter()
	self.timer = 0
	self.index = self.index + 1
	self.text = self.__target:sub(1, self.index)
	if self.sound then game.sound.play(self.sound) end
	self:setText()
end

function AtlasText:__makeChar(x, y, char)
	if char ~= "\n" and char ~= " " and char ~= "	" then
		return AtlasChar(x, y, self.font, self.imageData, char)
	end
	return {width = self:getCharWidth(char)}
end

function AtlasText:__render(camera)
	local list = self.__cameraRenderQueue[camera]
	if not list then return end

	for i, member in ipairs(list) do
		member:__batch(self.__batch, camera)
		list[i] = nil
	end
	self.__cameraRenderQueue[camera] = nil
	table.insert(self.__unusedCameraRenderQueue, list)

	local oldState = Object.saveDrawState()
	local min, mag, anisotropy = self.__batch:getTexture():getFilter()
	local mode = self.antialiasing and "linear" or "nearest"
	self.__batch:getTexture():setFilter(mode, mode, anisotropy)

	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = x + ox - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		y + oy - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	love.graphics.setColor(Color.vec4(self.color, self.alpha))
	love.graphics.setBlendMode(self.blend)
	love.graphics.setShader(self.shader)

	love.graphics.draw(self.__batch, x, y, rad, sx, sy, ox, oy)

	self.__batch:getTexture():setFilter(min, mag, anisotropy)
	Object.loadDrawState(oldState)
end

function AtlasText:__clear()
	for i = #self.members, 1, -1 do
		local char = self.members[i]
		char:destroy()
		self:remove(char)
	end
	if self.__batch then self.__batch:clear() end
	self.__lines = {}
end

function AtlasText:destroy()
	self:__clear()
	if self.__batch then self.__batch:release() end
	AtlasText.super.destroy(self)
end

return AtlasText
