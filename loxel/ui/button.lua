---@class Button:Object
local Button = Object:extend("Button")

function Button:new(x, y, width, height, text, callback)
	Button.super.new(self, x, y)

	self.width = width or 80
	self.height = height or 20

	self.text = text or "Button"
	self.font = love.graphics.getFont()
	self.font:setFilter("nearest", "nearest")

	self.hovered = false
	self.callback = callback
	self.color = { 0.5, 0.5, 0.5 }
	self.textColor = { 1, 1, 1 }
end

function Button:update()
	local mx, my = Mouse.x, Mouse.y
	self.hovered =
		(mx >= self.x and mx <= self.x + self.width and my >= self.y and my <=
			self.y + self.height)

	if Mouse.justPressed then
		if Mouse.justPressedLeft then
			self:mousepressed(Mouse.x, Mouse.y, Mouse.LEFT)
		elseif Mouse.justPressedRight then
			self:mousepressed(Mouse.x, Mouse.y, Mouse.RIGHT)
		elseif Mouse.justPressedMiddle then
			self:mousepressed(Mouse.x, Mouse.y, Mouse.MIDDLE)
		end
	end
end

function Button:__render(camera)
	local r, g, b, a = love.graphics.getColor()

	love.graphics.setColor(self.color[1], self.color[2], self.color[3],
		self.alpha)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	if self.hovered then
		love.graphics.setColor(0.2, 0.2, 0.2, self.alpha)
	else
		love.graphics.setColor(0, 0, 0, self.alpha)
	end
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

	local textX = self.x + (self.width - self.font:getWidth(self.text)) / 2
	local textY = self.y + (self.height - self.font:getHeight()) / 2

	love.graphics.setColor(self.textColor[1], self.textColor[2],
		self.textColor[3], self.alpha)
	love.graphics.print(self.text, textX, textY)

	love.graphics.setColor(r, g, b, a)
end

function Button:mousepressed(x, y, button)
	if self.hovered and self.callback then self.callback() end
end

return Button
