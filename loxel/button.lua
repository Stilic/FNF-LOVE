---@class Button:Graphic
local Button = Graphic:extend("Button")

function Button:new(x, y, width, height, key, color)
	Button.super.new(self, x, y)
	self.width = width
	self.height = height
	self.key = key
	self.color = color or {0.18, 0.18, 0.25}

	self.scrollFactor = {x = 0, y = 0}

	self.pressed = false
	self.pressedAlpha = 1
	self.releasedAlpha = 0.25

	self.alpha = self.releasedAlpha

	self.stunned = false

	self.lined = true
	self.pressedLineWidth = 4
	self.releasedLineWidth = 2

	self.line.width = self.releasedLineWidth
	self.config.round = {18, 18}
end

function Button:update(dt)
	if not self.pressed then
		self.alpha = math.lerp(self.releasedAlpha, self.alpha, math.exp(-dt * 14.4))
		self.line.width = math.lerp(self.releasedLineWidth, self.line.width, math.exp(-dt * 12))
	else
		self.alpha = self.pressedAlpha
		self.line.width = self.pressedLineWidth
	end
end

return Button
