local Camera = Object:extend()

function Camera:new(x, y, width, height)
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	if width == nil then width = 0 end
	if width <= 0 then width = push.getWidth() end
	if height == nil then height = 0 end
	if height <= 0 then height = push.getHeight() end
	self.x = x
	self.y = y
	self.target = nil
	self.width = width
	self.height = height
	self.angle = 0
	self.zoom = 1
end

function Camera:getPosition(x, y)
	return x - (self.target == nil and 0 or self.target.x) + self.width * 0.5,
	       y - (self.target == nil and 0 or self.target.y) + self.height * 0.5
end

function Camera:attach()
	love.graphics.push()

	local w2, h2 = self.width * 0.5, self.height * 0.5
	love.graphics.scale(self.zoom)
	love.graphics.translate(w2 / self.zoom - w2, h2 / self.zoom - h2)
	love.graphics.translate(-self.x, -self.y)
	love.graphics.translate(w2, h2)
	love.graphics.rotate(-self.angle)
	love.graphics.translate(-w2, -h2)
end

function Camera:detach() love.graphics.pop() end

return Camera
