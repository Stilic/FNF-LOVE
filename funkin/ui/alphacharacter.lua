local AlphaCharacter = Sprite:extend("AlphaCharacter")

AlphaCharacter.row = 0
AlphaCharacter.textSize = 1

function AlphaCharacter:new(x, y, font, textSize)
	AlphaCharacter.super.new(self, x, y)
	self.font = font or paths.getJSON("data/fonts/default")

	local tex = paths.getSparrowAtlas('fonts/' .. self.font.name)
	self:setFrames(tex)

	self:setGraphicSize(math.floor(self.width * textSize))
	self:updateHitbox()
	self.textSize = textSize
	self.antialiasing = true
end

function AlphaCharacter:createCharacter(letter)
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
	else
		print (prefix .. " is missing!!")
	end
	self:updateHitbox()

	self.y = (110 - self.height) + self.row * 60

	self.x, self.y = self.x - ox, self.y - oy
end

return AlphaCharacter
