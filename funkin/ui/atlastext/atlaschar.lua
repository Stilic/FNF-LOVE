local AtlasChar = Sprite:extend("AtlasChar")

function AtlasChar:new(x, y, font, char)
	AtlasChar.super.new(self, x, y)

	self.font = font or "default"
	self.char = char or "#"
	self:setFont()
	self:setChar()
end

function AtlasChar:setFont(font)
	if font and self.font == font then return end
	self.font = font or self.font
	self:setFrames(paths.getSparrowAtlas('fonts/' .. self.font.name))

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

return AtlasChar
