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
	self:addAnimByPrefix(letter, letter:lower() .. " bold instance", 24)
	self:play(letter)
	self:updateHitbox()
end

function AlphaCharacter:createBoldNumber(letter)
	self:addAnimByPrefix(letter, letter .. ' bold instance', 24)
	self:play(letter)
	self:updateHitbox()
end

function AlphaCharacter:createBoldSymbol(letter)
	switch(letter, {
		["."] = function()
			self:addAnimByPrefix(letter, 'period bold instance', 24)
		end,
		['"'] = function()
			self:addAnimByPrefix(letter, 'quote bold instance', 24)
		end,
		[","] = function()
			self:addAnimByPrefix(letter, 'comma bold instance', 24)
		end,
		["\\"] = function()
			self:addAnimByPrefix(letter, 'back slash bold instance', 24)
		end,
		["/"] = function()
			self:addAnimByPrefix(letter, 'forward slash bold instance', 24)
		end,
		["'"] = function()
			self:addAnimByPrefix(letter, 'apostrophe bold instance', 24)
		end,
		["!"] = function()
			self:addAnimByPrefix(letter, 'exclamation bold instance', 24)
		end,
		["?"] = function()
			self:addAnimByPrefix(letter, 'question bold instance', 24)
		end,
		["¡"] = function()
			self:addAnimByPrefix(letter, 'inverted exclamation bold instance', 24)
		end,
		["¿"] = function()
			self:addAnimByPrefix(letter, 'inverted question bold instance', 24)
		end,
		["•"] = function()
			self:addAnimByPrefix(letter, 'bullet bold instance', 24)
		end,
		default = function()
			self:addAnimByPrefix(letter, letter .. ' bold instance', 24)
		end
	})
	self:play(letter)
	self:updateHitbox()
end

function AlphaCharacter:createLetter(letter)
	local letterCase = "lowercase"
	if letter:lower() ~= letter then letterCase = "" end

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
