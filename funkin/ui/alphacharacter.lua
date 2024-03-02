local AlphaCharacter = Sprite:extend("AlphaCharacter")

AlphaCharacter.row = 0
AlphaCharacter.textSize = 1

function AlphaCharacter:new(x, y, textSize)
	AlphaCharacter.super.new(self, x, y)
	local tex = paths.getSparrowAtlas('menus/alphabet')
	self:setFrames(tex)

	self:setGraphicSize(math.floor(self.width * textSize))
	self:updateHitbox()
	self.textSize = textSize
	self.antialiasing = true
end

function AlphaCharacter:createBoldLetter(letter)
	self:addAnimByPrefix(letter, letter:upper() .. " bold", 24)
	self:play(letter)
	self:updateHitbox()
end

function AlphaCharacter:createBoldNumber(letter)
	self:addAnimByPrefix(letter, "bold" .. letter, 24)
	self:play(letter)
	self:updateHitbox()
end

function AlphaCharacter:createBoldSymbol(letter)
	switch(letter, {
		["."] = function()
			self:addAnimByPrefix(letter, 'PERIOD bold', 24)
		end,
		["\'"] = function()
			self:addAnimByPrefix(letter, 'APOSTRAPHIE bold', 24)
		end,
		["?"] = function()
			self:addAnimByPrefix(letter, 'QUESTION MARK bold', 24)
		end,
		["!"] = function()
			self:addAnimByPrefix(letter, 'EXCLAMATION POINT bold', 24)
		end,
		["("] = function() self:addAnimByPrefix(letter, 'bold (', 24) end,
		[")"] = function() self:addAnimByPrefix(letter, 'bold )', 24) end,
		default = function()
			self:addAnimByPrefix(letter, 'bold ' .. letter, 24)
		end
	})
	self:play(letter)
	self:updateHitbox()
	switch(letter, {
		["\'"] = function() self.y = self.y - 20 * self.textSize end,
		["-"] = function() self.y = self.y + 20 * self.textSize end,
		["("] = function()
			self.x = self.x - 65 * self.textSize
			self.y = self.y - 5 * self.textSize
			self.offset.x = -58 * self.textSize
		end,
		[")"] = function()
			self.x = self.x - 20 / self.textSize
			self.y = self.y - 5 * self.textSize
			self.offset.x = 12 * self.textSize
		end,
		["."] = function()
			self.y = self.y + 45 * self.textSize
			self.x = self.x + 5 * self.textSize
			self.offset.x = self.offset.x + 3 * self.textSize
		end
	})
end

function AlphaCharacter:createLetter(letter)
	local letterCase = "lowercase"
	if letter:lower() ~= letter then letterCase = "capital" end

	self:addAnimByPrefix(letter, letter .. " " .. letterCase, 24)
	self:play(letter)
	self:updateHitbox()

	self.y = (110 - self.height)
	self.y = self.y + self.row * 60
end

function AlphaCharacter:createNumber(letter)
	self:addAnimByPrefix(letter, letter, 24)
	self:play(letter)

	self:updateHitbox()

	self.y = (110 - self.height)
	self.y = self.y + self.row * 60
end

function AlphaCharacter:createSymbol(letter)
	switch(letter, {
		["#"] = function() self:addAnimByPrefix(letter, 'hashtag', 24) end,
		["."] = function() self:addAnimByPrefix(letter, 'period', 24) end,
		["\'"] = function()
			self:addAnimByPrefix(letter, 'apostraphie', 24)
		end,
		["?"] = function()
			self:addAnimByPrefix(letter, 'question mark', 24)
		end,
		["!"] = function()
			self:addAnimByPrefix(letter, 'exclamation point', 24)
		end,
		[","] = function() self:addAnimByPrefix(letter, 'comma', 24) end,
		default = function() self:addAnimByPrefix(letter, letter, 24) end
	})
	self:play(letter)

	self:updateHitbox()

	self.y = (110 - self.height)
	self.y = self.y + self.row * 60
	switch(letter, {
		["\'"] = function() self.y = self.y - 20 end,
		["-"] = function() self.y = self.y - 16 end
	})
end

return AlphaCharacter
