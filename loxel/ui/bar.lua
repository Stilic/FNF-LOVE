---@class Bar:Object
local Bar = Object:extend("Bar")

function Bar:new(x, y, width, height, min, max, isFilled)
	Bar.super.new(self, x, y)

	self.width = width or 100
	self.height = height or 10
	self.min, self.max = min or 0, max or 100
	self.filled = isFilled

	self.value = 0
	self.fillWidth = 0
	self.percent = 0

	self.color = Color.GREEN
	self.color.bg = Color.RED

	self:updateValues()
end

function Bar:setValue(value)
	self.value = math.min(math.max(value, self.min), self.max)
end

function Bar:update()
	self:updateValues()
end

function Bar:updateValues()
	self.fillWidth = self.width - ((self.value / self.max) * self.width)
	self.percent = (self.value / self.max) * 100
end

function Bar:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local shader = love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	if self.shader then love.graphics.setShader(self.shader) end
	love.graphics.setBlendMode(self.blend)

	love.graphics.push()
	love.graphics.rotate(math.rad(self.angle))
	if self.filled then
		local color = self.flipX and self.color.bg or self.color
		love.graphics.setColor(color[1], color[2], color[3], self.alpha)
		love.graphics.rectangle("fill", x + self.fillWidth, y,
			self.width - self.fillWidth, self.height)
	end

	local color = self.flipX and self.color or self.color.bg
	love.graphics.setColor(color[1], color[2], color[3], self.alpha)
	love.graphics.rectangle("fill", x, y, self.fillWidth, self.height)
	love.graphics.pop()

	love.graphics.setColor(r, g, b, a)
	if self.shader then love.graphics.setShader(shader) end
	love.graphics.setBlendMode(blendMode, alphaMode)
end

return Bar
