local AtlasChar = Sprite:extend("AtlasChar")

function AtlasChar:new(x, y, font, size)
	AtlasChar.super.new(self, x, y)
	self:setFont(font, size)
end

function AtlasChar:setFont(font, size)
	self.font = font
	local tex = paths.getSparrowAtlas('fonts/' .. self.font.name)

	self:setFrames(tex)
	self:updateHitbox()

	self.size = size or self.font.size or self.width

	self:setGraphicSize(self.size)
	self:updateHitbox()

	self.antialiasing = self.font.antialiasing ~= nil and
		self.font.antialiasing or true
end

function AtlasChar:setChar(letter)
	local prefix = tostring(letter)
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
	local y = 110 - self.height
	self.offset = {x = ox, y = oy - y}
end

return AtlasChar
