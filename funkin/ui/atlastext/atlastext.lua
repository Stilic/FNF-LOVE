local AtlasCharGroup = require "funkin.ui.atlastext.atlaschargroup"
local AtlasText = SpriteGroup:extend("AtlasText")

function AtlasText:new(x, y, text, font, typed, limit, align)
	AtlasText.super.new(self, x or 0, y or 0)

	self.text = text or ""
	self.limit = limit or 0
	self.align = align or "left"
	-- Align can be left, right or center

	self.font = paths.getJSON("data/fonts/" .. font or "default")

	self.typed = typed or false
	self.target = self.text
	self.speed = 0.04
	self.timer = 0
	self.index = 0
	self.sound = nil
	self.completeCallback = nil
	if self.typed then self.text = "" end

	self.__textGrp = AtlasCharGroup(self.font)
	self:add(self.__textGrp)

	if self.text ~= "" then
		self:updateText()
	end
	Timer.after(5, function()
		self:setFont("white")
	end)
end

function AtlasText:setFont(font)
	self.font = paths.getJSON("data/fonts/" .. font)
	self.__textGrp:setFont(self.font)
end

function AtlasText:updateText()
	self.__textGrp:setText(self.text, self.limit, self.align)
	self:updateHitbox()
end

function AtlasText:getWidth()
	if self.limit > 0 then
		return self.limit
	else
		return AtlasText.super.getWidth(self)
	end
	return 0
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

function AtlasText:resetText(text)
	if not self.typed then return end

	self.text = ""
	self.timer = 0
	self.index = 0
	self.target = text
	self.finished = false
end

function AtlasText:forceEnd()
	if not self.typed then return end

	self.text = self.target
	self.finished = true
	if self.completeCallback then self.completeCallback() end
end

function AtlasText:addLetter()
	self.timer = 0
	self.index = self.index + 1

	self.text = string.sub(self.target, 1, self.index)
	if self.sound then game.sound.play(self.sound) end

	self:updateText()
end

return AtlasText
