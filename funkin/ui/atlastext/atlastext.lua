local AtlasText = SpriteGroup:extend("AtlasText")
local AtlasChar = require "funkin.ui.atlastext.atlaschar"

AtlasText.tabSize = 2
AtlasText.lineSize = 80
AtlasText.spaceWidth = 50

function AtlasText.getCharWidth(char, fnt)
	local obj = AtlasChar(0, 0, fnt, char)
	local width = obj.width
	obj:destroy()
	return width
end

function AtlasText.getFont(font, size)
	font = font or "default"
	local func = Mods.currentMod and paths.getMods or function(...)
		return paths.getPath(..., false)
	end

	local exists = paths.exists(func("data/fonts/" .. font .. ".json"), "file")
	local font = paths.getJSON("data/fonts/" .. (exists and font or "default"))
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
	-- Align can be left, right, or center

	self.font = nil
	self:setFont(font)
	self:setTyping(0)

	self.__lines = {}

	self:setText()
	return self
end

function AtlasText:setTyping(speed, sound)
	self.typed = (speed > 0)
	self.target, self.text = self.text, ""
	self.speed, self.timer, self.index = 0.04, 0, 0
	self.sound, self.completeCallback = sound, nil
	self.finished = not self.typed

	self:setText()
end

function AtlasText:setFont(font, size)
	if (font and self.font == font) and (size and self.size == size) then
		return
	end

	self.font = type(font) == "string" and
		AtlasText.getFont(font) or font
	self:setText(self.text)
end

function AtlasText:setText(text)
	self:__clear()

	if text then self.text = text end

	local curLine = ""
	local width = 0

	for i = 1, #self.text do
		local char = self.text:sub(i, i)
		if char == " " then
			curLine = curLine .. char
			width = width + self.font.spaceWidth * self.font.scale
		elseif char == "	" then -- tab
			curLine = curLine .. char
			width = width + (self.font.spaceWidth * AtlasText.tabSize) * self.font.scale
		elseif char == "\n" or (self.limit > 0 and width >= self.limit) then
			table.insert(self.__lines, {text = curLine, width = width})
			curLine = (char == "\n" or char == " ") and "" or char
			width = char == "\n" and 0 or AtlasText.getCharWidth(char, self.font)
		else
			local letterWidth = AtlasText.getCharWidth(char, self.font)
			curLine = curLine .. char
			width = width + letterWidth
		end
	end

	if #curLine > 0 then
		table.insert(self.__lines, {text = curLine, width = width})
	end

	if not self.__lines then return end
	local y = 0
	for _, line in ipairs(self.__lines) do
		self:__createLine(line.text, y, line.width, self.align, self.limit)
		y = y + self.font.lineSize
	end

	self:updateHitbox()
end

function AtlasText:update(dt)
	if self.typed and not self.finished then
		self.timer = self.timer + dt
		if self.timer >= self.speed then
			self:addLetter()
		end

		if self.index == #self.target then
			self.finished = true
			if self.completeCallback then self.completeCallback() end
		end
	end

	AtlasText.super.update(self, dt)
end

function AtlasText:forceEnd()
	if not self.typed then return end

	self.text = self.target
	self.finished = true
	if self.completeCallback then self.completeCallback() end
end

function AtlasText:addLetter()
	if not self.typed then return end

	self.timer = 0
	self.index = self.index + 1

	self.text = string.sub(self.target, 1, self.index)
	if self.sound then game.sound.play(self.sound) end

	self:setText()
end

function AtlasText:__createLine(textL, y, lineWidth)
	local x, xOff = 0, 0

	if self.align == "center" then
		xOff = (self.limit - lineWidth) / 2
	elseif self.align == "right" then
		xOff = self.limit - lineWidth
	end

	for i = 1, #textL do
		local char = textL:sub(i, i)
		if char == " " then
			x = x + self.font.spaceWidth * self.font.scale
		elseif char == "	" then -- tab
			x = x + (self.font.spaceWidth * AtlasText.tabSize) * self.font.scale
		elseif char ~= "\n" then
			local letter = AtlasChar(x + xOff, y, self.font, char)
			x = x + letter.width
			self:add(letter)
		end
	end
end

function AtlasText:__clear()
	if not self.members then return end

	for i = #self.members, 1, -1 do
		local char = self.members[i]
		char:destroy()
		self:remove(char)
	end
	self.__lines = {}
end

return AtlasText
