local AtlasChar = Sprite:extend("AtlasChar")

function AtlasChar:new(x, y, font, imageData, char)
	AtlasChar.super.new(self, x, y)

	self.font = font or "default"
	self.char = char or "#"
	if font then self:setFont(nil, imageData) end
	if char then self:setChar() end
end

function AtlasChar:setFont(font, frames)
	if font and self.font == font then return end
	self.font = font or self.font
	self:setFrames(frames)

	self:updateHitbox()
	self:setGraphicSize(self.width * self.font.scale)
	self:updateHitbox()

	self.antialiasing = self.font.antialiasing ~= nil and
		self.font.antialiasing or true
end

function AtlasChar:setChar(letter)
	if letter and self.char == letter then return end
	self.char = letter or self.char

	local prefix = tostring(self.char)
	local ox, oy = self.font.offsets[1], self.font.offsets[2]

	if self.font.noUpper then prefix = prefix:lower() end
	if self.font.noLower then prefix = prefix:upper() end

	for _, char in ipairs(self.font.specChars) do
		if char.letter == prefix then
			prefix = char.prefix
			if char.offsets then
				ox, oy = ox - char.offsets[1], ox - char.offsets[2]
			end
			break
		end
	end

	self:addAnimByPrefix(prefix, prefix, self.font.framerate or 24)
	if self.__animations and self.__animations[prefix] then
		self:play(prefix)
	end
	self:updateHitbox()

	local scale = self.font.scale
	local x, y = ox * scale, (oy - (110 - self.height)) * scale
	self.offset = {x = x, y = y}
end

function AtlasChar:__render()
	return -- do not render anything, this will be done at __batch
end

function AtlasChar:__batch(batch, camera)
	batch:setColor(Color.vec4(self.color, self.alpha))

	local f = self:getCurrentFrame()
	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = x + ox - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		y + oy - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	if f then
		ox, oy = ox + f.offset.x, oy + f.offset.y
		if not self._batchIndex then
			self._batchIndex = batch:add(f.quad, x, y, rad, sx, sy, ox, oy)
		else
			batch:set(self._batchIndex, f.quad, x, y, rad, sx, sy, ox, oy)
		end
	else
		if not self._batchIndex then
			self._batchIndex = batch:add(x, y, rad, sx, sy, ox, oy)
		else
			batch:set(self._batchIndex, x, y, rad, sx, sy, ox, oy)
		end
	end
end

return AtlasChar
