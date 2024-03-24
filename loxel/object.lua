local abs, rad, cos, sin = math.abs, math.rad, math.fastcos, math.fastsin
local function checkCollisionFast(x1, y1, w1, h1, a1, x2, y2, w2, h2, a2)
	local hw1, hw2, hh1, hh2 = w1 / 2, w2 / 2, h1 / 2, h2 / 2
	local rad1, rad2 = rad(a1), rad(a2)
	local sin1, cos1 = abs(sin(rad1)), abs(cos(rad1))
	local sin2, cos2 = abs(sin(rad2)), abs(cos(rad2))

	return abs(x2 + hw2 - x1 - hw1) - hw1 * cos1 - hh1 * sin1 - hw2 * cos2 - hh2 * sin2 < 0
		and abs(y2 + hh2 - y1 - hh1) - hh1 * cos1 - hw1 * sin1 - hh2 * cos2 - hw2 * sin2 < 0
end

---@class Object:Basic
local Object = Basic:extend("Object")
Object.checkCollisionFast = checkCollisionFast
Object.defaultAntialiasing = false

function Object:new(x, y)
	Object.super.new(self)

	self:setPosition(x, y)
	self.width, self.height = 0, 0

	self.offset = {x = 0, y = 0}
	self.origin = {x = 0, y = 0}
	self.scale = {x = 1, y = 1}
	self.zoom = {x = 1, y = 1} -- same as scale
	self.scrollFactor = {x = 1, y = 1}
	self.flipX = false
	self.flipY = false

	self.shader = nil
	self.antialiasing = Object.defaultAntialiasing or false
	self.color = {1, 1, 1}
	self.blend = "alpha"

	self.alpha = 1
	self.angle = 0

	self.moves = false
	self.velocity = {x = 0, y = 0}
	self.acceleration = {x = 0, y = 0}
end

function Object:destroy()
	Object.super.destroy(self)

	self.offset.x, self.offset.y = 0, 0
	self.scale.x, self.scale.y = 1, 1

	self.shader = nil
end

function Object:setPosition(x, y)
	self.x, self.y = x or 0, y or 0
end

function Object:setScrollFactor(x, y)
	self.scrollFactor.x, self.scrollFactor.y = x or 0, y or x or 0
end

function Object:getMidpoint()
	return self.x + self.width / 2, self.y + self.height / 2
end

function Object:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.width) / 2 end
	if axes:find("y") then self.y = (game.height - self.height) / 2 end
	return self
end

function Object:updateHitbox()
	local width, height
	if self.getWidth then width, height = self:getWidth(), self:getHeight() end
	self:centerOffsets(width, height)
	self:centerOrigin(width, height)
end

function Object:centerOffsets(__width, __height)
	self.offset.x = ((__width or self.width) - self.width) / 2
	self.offset.y = ((__height or self.height) - self.height) / 2
end

function Object:centerOrigin(__width, __height)
	self.origin.x = (__width or self.width) / 2
	self.origin.y = (__height or self.height) / 2
end

function Object:getMultColor(r, g, b, a)
	local c = self.color
	return c[1] * math.min(r, 1), c[2] * math.min(g, 1), c[3] * math.min(b, 1),
		self.alpha * (math.min(a or 1, 1))
end

function Object:update(dt)
	if self.moves then
		self.velocity.x = self.velocity.x + self.acceleration.x * dt
		self.velocity.y = self.velocity.y + self.acceleration.y * dt

		self.x = self.x + self.velocity.x * dt
		self.y = self.y + self.velocity.y * dt
	end
end

function Object:_collides(x, y, w, h, ...)
	local o = (...)
	if not o then return false end

	local x2, y2, w2, h2 = o:_getXYWH()
	return checkCollisionFast(x, y, w, h, self.angle, x2, y2, w2, h2, o.angle)
		or self:_collides(x, y, w, h, select(2, ...))
end

function Object:collides(...)
	local x, y, w, h = self:_getXYWH()
	return self:_collides(x, y, w, h, ...)
end

local tempCameras = table.new(1, 0)
function Object:isOnScreen(cameras)
	if cameras.x then
		tempCameras[1] = cameras
		return self:isOnScreen(tempCameras)
	end

	local sf, x, y, w, h, x2, y2 = self.scrollFactor, self:_getXYWH()
	for _, c in pairs(cameras) do
		if sf then
			x2, y2 = x - c.scroll.x * sf.x, y - c.scroll.y * sf.y
		else
			x2, y2 = x - c.scroll.x, y - c.scroll.y
		end

		local zx, zy = c:getZoomXY()
		if checkCollisionFast(x2, y2, w, h, self.angle or 0,
				c.x, c.y, c.width * zx, c.height * zy, c.angle)
		then
			return true
		end
	end

	return false
end

function Object:_canDraw()
	return self.alpha > 0 and (self.scale.x * self.zoom.x ~= 0 or
		self.scale.y * self.zoom.y ~= 0) and Object.super._canDraw(self)
end

function Object:_getXYWH()
	local x, y = self.x or 0, self.y or 0
	if self.offset ~= nil then x, y = x + self.offset.x, y + self.offset.y end
	if self.getCurrentFrame then
		local f = self:getCurrentFrame()
		if f then x, y = x + f.offset.x, y + f.offset.y end
	end

	local w, h = abs(self.scale.x * self.zoom.x), abs(self.scale.y * self.zoom.y)
	if self.getWidth then
		w, h = self:getWidth() * w, self:getHeight() * h
	else
		w, h = (self.getFrameWidth and self:getFrameWidth() or self.width or 0) * w,
			(self.getFrameHeight and self:getFrameHeight() or self.height or 0) * h
	end

	return x, y, w, h
end

return Object
