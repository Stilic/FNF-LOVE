local source = (...) and (...):gsub('%.oldui.slider$', '.') or ""
local Basic = require(source .. "basic")

local Slider = Basic:extend("Slider")

function Slider:new(x, y, width, height, value, sliderType, min, max)
	Slider.super.new(self)

	self.x = x or 0
	self.y = y or 0
	self.width = width
	self.height = height
	self.value = value or 0
	self.isDragging = false
	self.sliderType = sliderType == nil and "horizontal" or sliderType:lower()
	self.bgColor = {1, 1, 1}
	self.knobColor = {0.3, 0.3, 0.3}
	self.min = min or 0
	self.max = max or 1

	-- init knob pos
	if self.sliderType == "horizontal" then
		local clampedX = math.max(self.min,
			math.min(self.width - self.height, self.x))
		self.value = self.min + (clampedX / (self.width - self.height)) *
			(self.max - self.min)
	elseif self.sliderType == "vertical" then
		local clampedY = math.max(self.min,
			math.min(self.height - self.width, self.y))
		self.value = self.min + (clampedY / (self.height - self.width)) *
			(self.max - self.min)
	end
end

function Slider:update()
	if self.isDragging then
		if self.sliderType == "horizontal" then
			local relativeX = (game.mouse.x - self.height / 2) - self.x
			local clampedX = math.max(self.min, math.min(
				self.width - self.height, relativeX))
			self.value = self.min + (clampedX / (self.width - self.height)) *
				(self.max - self.min)
		elseif self.sliderType == "vertical" then
			local relativeY = (game.mouse.y - self.width / 2) - self.y
			local clampedY = math.max(self.min, math.min(
				self.height - self.width, relativeY))
			self.value = self.min + (clampedY / (self.height - self.width)) *
				(self.max - self.min)
		end
	end

	if game.mouse.justPressed then
		if game.mouse.justPressedLeft then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.LEFT)
		elseif game.mouse.justPressedRight then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.RIGHT)
		elseif game.mouse.justPressedMiddle then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.MIDDLE)
		end
	end
	if game.mouse.justReleased then
		if game.mouse.justReleasedLeft then
			self:mousereleased(game.mouse.x, game.mouse.y, game.mouse.LEFT)
		elseif game.mouse.justReleasedRight then
			self:mousereleased(game.mouse.x, game.mouse.y, game.mouse.RIGHT)
		elseif game.mouse.justReleasedMiddle then
			self:mousereleased(game.mouse.x, game.mouse.y, game.mouse.MIDDLE)
		end
	end
end

function Slider:__render(camera)
	love.graphics.setColor(self.bgColor)
	if self.sliderType == "horizontal" then
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
		local knobX = self.x + (self.value - self.min) / (self.max - self.min) *
			(self.width - self.height)
		local knobY = self.y + self.height / 2
		love.graphics.setColor(self.knobColor)
		love.graphics.rectangle("fill", knobX, knobY - self.height / 2,
			self.height, self.height)
	elseif self.sliderType == "vertical" then
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
		local knobX = self.x + self.width / 2
		local knobY = self.y + (self.value - self.min) / (self.max - self.min) *
			(self.height - self.width)
		love.graphics.setColor(self.knobColor)
		love.graphics.rectangle("fill", knobX - self.width / 2, knobY,
			self.width, self.width)
	end
end

function isInside(self, x, y)
	return x >= self.x and x <= self.x + self.width and y >= self.y and y <=
		self.y + self.height
end

function Slider:mousepressed(x, y, button)
	self.isDragging =
		(button == game.mouse.LEFT and isInside(self, game.mouse.x, game.mouse.y))
end

function Slider:mousereleased(x, y, button)
	if button == game.mouse.LEFT then self.isDragging = false end
end

return Slider
