local AlphaCharacter = require "funkin.ui.alphacharacter"

local Alphabet = SpriteGroup:extend("Alphabet")

Alphabet.delay = 0.05
Alphabet.paused = false

-- for menu shit
Alphabet.forceX = math.negative_infinity
Alphabet.targetY = 0
Alphabet.yMult = 120
Alphabet.xAdd = 0
Alphabet.yAdd = 0
Alphabet.isMenuItem = false
Alphabet.textSize = 1.0

Alphabet.text = ""

Alphabet.__finalText = ""
Alphabet.yMulti = 1

Alphabet.lastSprite = nil
Alphabet.xPosResetted = false

Alphabet.splitWords = {}

Alphabet.isBold = false
Alphabet.lettersArray = {}

Alphabet.finishedText = false
Alphabet.typed = false

Alphabet.typingSpeed = 0.05

function Alphabet:new(x, y, text, font, typed, typingSpeed, textSize)
	if text == nil then text = "" end
	if font == nil then font = "default" end
	if typed == nil then typed = false end
	if typingSpeed == nil then typingSpeed = 0.05 end
	if textSize == nil then textSize = 1 end

	Alphabet.super.new(self, x, y)

	self.forceX = math.negative_infinity
	self.textSize = textSize

	self.__finalText = text
	self.text = text
	self.typed = typed
	self.font = paths.getJSON("data/fonts/" .. font)

	if self.text ~= "" then
		if self.typed then
		else
			self:addText()
		end
	else
		self.finishedText = true
	end
end

function Alphabet:addText()
	self:doSplitWords()

	local xPos = 0
	for i, character in ipairs(self.splitWords) do
		local spaceChar = character == " "
		if spaceChar then
			self.consecutiveSpace = self.consecutiveSpace + 1
		end
		if not spaceChar then
			if self.lastSprite ~= nil then
				xPos = self.lastSprite.x + self.lastSprite.width
			end
			if self.consecutiveSpace > 0 then
				xPos = xPos + 40 * self.consecutiveSpace * self.textSize
			end
			self.consecutiveSpace = 0

			local letter = AlphaCharacter(xPos, 0, self.font, self.textSize)
			letter:createCharacter(character)
			self:add(letter)
			table.insert(self.lettersArray, letter)

			self.lastSprite = letter
		end
	end

	self:updateHitbox()
end

function Alphabet:doSplitWords() self.splitWords = self.__finalText:split() end

Alphabet.consecutiveSpace = 0

function Alphabet:update(dt)
	if self.isMenuItem then
		self.y = util.coolLerp(self.y,
			(math.remapToRange(self.targetY, 0, 1, 0, 1.3) * self.yMult) + (game.height * 0.48) + self.yAdd,
			9.6, dt
		)
		if self.forceX ~= math.negative_infinity then
			self.x = self.forceX
		else
			self.x = util.coolLerp(self.x, (self.targetY * 20) + 90 + self.xAdd, 9.6, dt)
		end
	end

	Alphabet.super.update(self, dt)
end

return Alphabet
