---@class Button:Graphic
local Button = Graphic:extend("Button")

function Button:new(x, y, width, height, key, color)
	Button.super.new(self, x, y)
	self.width = width
	self.height = height
	self.key = key
	self.color = color or {0.2, 0.2, 0.2}

	self.scrollFactor = {x = 0, y = 0}

	self.pressed = false
	self.pressedAlpha = 1
	self.releasedAlpha = 0.25

	self.stunned = false
end

function Button:setColor(color) self.color = color end

function Button:update(dt)
	if not self.pressed then
		self.alpha = math.lerp(self.releasedAlpha,  self.alpha, math.exp(-dt * 14.4))
	else
		self.alpha = self.pressedAlpha
	end
end

return Button
