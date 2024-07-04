local AtlasChar = require "funkin.ui.atlastext.atlaschar"
local AtlasCharGroup = SpriteGroup:extend("AtlasCharGroup")

function AtlasChar.getCharWidth(font, char)
	local obj = AtlasChar(0, 0, font)
	obj:setChar(char)
	local width = obj.width
	obj:destroy()

	return width
end

function AtlasCharGroup:new(font)
	AtlasCharGroup.super.new(self, 0, 0)

	self.lines = {}
	self.text = ""
	self.font = font

	self.font.lineSize = self.font.lineSize or 80
	self.font.spaceWidth = self.font.spaceWidth or 50
end

function AtlasCharGroup:setText(text, limit, align)
	self:cleanup()

	self.text = text
	limit, align = limit or 0, align

	local curLine = ""
	local curLineWidth = 0

	for i = 1, #text do
		local char = text:sub(i, i)
		if char == " " then
			curLine = curLine .. char
			curLineWidth = curLineWidth + self.font.spaceWidth
		elseif char == "	" then -- tab
			curLine = curLine .. char
			curLineWidth = curLineWidth + self.font.spaceWidth * 2
		elseif char == "\n" or (limit > 0 and curLineWidth >= limit) then
			table.insert(self.lines, {text = curLine, width = curLineWidth})
			curLine = (char == "\n" or char == " ") and "" or char
			curLineWidth = char == "\n" and 0 or AtlasChar.getCharWidth(self.font, char)
		else
			local width = AtlasChar.getCharWidth(self.font, char)
			curLine = curLine .. char
			curLineWidth = curLineWidth + width
		end
	end

	if #curLine > 0 then
		table.insert(self.lines, {text = curLine, width = curLineWidth})
	end

	local y = 0
	for _, line in ipairs(self.lines) do
		self:createLine(line.text, y, line.width, align, limit)
		y = y + self.font.lineSize
	end

	self:updateHitbox()
end

function AtlasCharGroup:createLine(textL, y, lineWidth, align, limit)
	local x, offsetX = 0, 0

	if align == "center" then
		offsetX = (limit - lineWidth) / 2
	elseif align == "right" then
		offsetX = limit - lineWidth
	end

	for i = 1, #textL do
		local char = textL:sub(i, i)
		if char == " " then
			x = x + self.font.spaceWidth
		elseif char ~= "\n" then
			local o = AtlasChar(x + offsetX, y, self.font)
			o:setChar(char)
			self:add(o)
			x = x + o.width
		end
	end
end

function AtlasCharGroup:setFont(font)
	self.font = font
	for i = #self.members, 1, -1 do
		local char = self.members[i]
		char:setFont(self.font)
	end
	self.font.lineSize = self.font.lineSize or 80
	self.font.spaceWidth = self.font.spaceWidth or 50
	self:setText(self.text)
end

function AtlasCharGroup:cleanup()
	for i = #self.members, 1, -1 do
		local char = self.members[i]
		char:destroy()
		self:remove(char)
	end
	self.lines = {}
end

return AtlasCharGroup
