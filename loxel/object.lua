local abs, rad, deg, atan, cos, sin, floor =
	math.abs, math.rad, math.deg, math.atan, math.fastcos, math.fastsin, math.floor
local function checkCollisionFast(
	x1, y1, w1, h1, sx1, sy1, ox1, oy1, a1,
	x2, y2, w2, h2, sx2, sy2, ox2, oy2, a2
)
	if w1 < 0 then w1 = w1 * 2; x1 = x1 + w1 end
	if h1 < 0 then h1 = h1 * 2; x1 = x1 + w1 end
	w1, h1 = math.abs(w1), math.abs(h1)
	local hw1, hw2, hh1, hh2 = w1 / 2, w2 / 2, h1 / 2, h2 / 2
	local rad1, rad2 = rad(a1), rad(a2)
	local sin1, cos1 = abs(sin(rad1)), abs(cos(rad1))
	local sin2, cos2 = abs(sin(rad2)), abs(cos(rad2))

	-- i hate this alot, but fuck it. -ralty
	-- todo: make it work for origin
	return abs(x2 + hw2 - x1 - hw1)
		- hw1 * cos1 * sx1 - hh1 * sin1 * sy1
		- hw2 * cos2 * sx2 - hh2 * sin2 * sy2 < 0
		and abs(y2 + hh2 - y1 - hh1)
		- hh1 * cos1 * sy1 - hw1 * sin1 * sx1
		- hh2 * cos2 * sy2 - hw2 * sin2 * sx2 < 0
end

---@class Object:Basic
local Object = Basic:extend("Object")
Object.checkCollisionFast = checkCollisionFast
Object.defaultAntialiasing = false

function Object.getAngleTowards(x, y, x2, y2)
	return deg(atan((x2 - x) / (y2 - y))) + (y > y2 and 180 or 0)
end

function Object:setupDrawLogic(camera, initDraw)
	if initDraw == nil then initDraw = true end
	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = x + ox - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		y + oy - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	if initDraw then
		love.graphics.setShader(self.shader); love.graphics.setBlendMode(self.blend)
		love.graphics.setColor(Color.vec4(self.color, self.alpha))
	end

	if camera.pixelPerfect then
		x, y, ox, oy = floor(x), floor(y), floor(ox), floor(oy)
	end

	return x, y, rad, sx, sy, ox, oy, self.skew.x, self.skew.y
end

local setfunc = function(self, x, y)
	self.x = x or self.x
	self.y = y or self.y
end

local function point(x, y)
	return {x = x, y = y, set = setfunc}
end

function Object:new(x, y)
	Object.super.new(self)

	self:setPosition(x, y)
	self.width, self.height = 0, 0

	self.offset = point(0, 0)
	self.origin = point(0, 0)
	self.scale = point(1, 1)
	self.zoom = point(1, 1) -- same as scale
	self.scrollFactor = point(1, 1)
	self.skew = point(0, 0)
	self.flipX = false
	self.flipY = false

	self.shader = nil
	self.antialiasing = Object.defaultAntialiasing or false
	self.color = Color.WHITE
	self.blend = "alpha"

	self.alpha = 1
	self.angle = 0

	self.moves = false
	self.velocity = point(0, 0)
	self.acceleration = point(0, 0)
end

function Object:destroy()
	Object.super.destroy(self)

	-- self.offset:set(0, 0)
	-- self.scale:set(1, 1)
	-- self.skew:set(0, 0)

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
	local centerAll = axes == nil or axes == "xy"
	if centerAll or axes == "x" then self.x = (game.width - self.width) / 2 end
	if centerAll or axes == "y" then self.y = (game.height - self.height) / 2 end
	return self
end

function Object:center(obj, axes)
	local centerAll = axes == nil or axes == "xy"
	local sw, sh = self.getWidth and self:getWidth() or self.width,
		self.getHeight and self:getHeight() or self.height

	if centerAll or axes == "x" then
		local w = obj.getWidth and obj:getWidth() or obj.width
		self.x = obj.x + (w - sw) / 2
	end
	if centerAll or axes == "y" then
		local h = obj.getHeight and obj:getHeight() or obj.height
		self.y = obj.y + (h - sh) / 2
	end
	return self
end

function Object:updateHitbox()
	local width, height
	if self.getWidth then width, height = self:getWidth(), self:getHeight() end
	self:fixOffsets(width, height)
	self:centerOrigin(width, height)
end

function Object:centerOffsets(__width, __height)
	self.offset.x = (__width or self.width) / 2
	self.offset.y = (__height or self.height) / 2
end

function Object:fixOffsets(__width, __height)
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

function Object:_isOnScreen(x, y, w, h, sx, sy, ox, oy, sfx, sfy, c)
	local x2, y2, w2, h2, sx2, sy2, ox2, oy2 = c:_getCameraBoundary()
	return checkCollisionFast(
		x - c.scroll.x * sfx, y - c.scroll.y * sfy, w, h, sx, sy, ox, oy, self.angle,
		x2, y2, w2, h2, sx2, sy2, ox2, oy2, c.angle
	)
end

function Object:isOnScreen(cameras)
	local sf = self.scrollFactor
	local sfx, sfy, x, y, w, h, sx, sy, ox, oy = sf and sf.x or 1, sf and sf.y or 1,
		self:_getBoundary(cameras)

	if cameras.x then return self:_isOnScreen(x, y, w, h, sx, sy, ox, oy, sfx, sfy, cameras) end

	for _, c in pairs(cameras) do
		if self:_isOnScreen(x, y, w, h, sx, sy, ox, oy, sfx, sfy, c) then return true end
	end
	return false
end

function Object:_canDraw()
	return self.alpha > 0 and (self.scale.x * self.zoom.x ~= 0 or
		self.scale.y * self.zoom.y ~= 0) and Object.super._canDraw(self)
end

-- i hate this too -ralty
function Object:_getBoundary()
	local x, y = self.x or 0, self.y or 0
	if self.offset ~= nil then x, y = x - self.offset.x, y - self.offset.y end
	if self.getCurrentFrame then
		local f = self:getCurrentFrame()
		if f then
			x = x - f.offset.x * (self.flipX and -1 or 1)
			y = y - f.offset.y * (self.flipY and -1 or 1)
		end
	end

	local w, h
	if self.getWidth then
		w, h = self:getWidth(), self:getHeight()
	else
		w, h = (self.getFrameWidth and self:getFrameWidth() or self.width or 0),
			(self.getFrameHeight and self:getFrameHeight() or self.height or 0)
	end

	if self.flipX then x = x + self.width; w = -w end
	if self.flipY then y = y + self.height; h = -h end

	return x, y, w, h, abs(self.scale.x * self.zoom.x), abs(self.scale.y * self.zoom.y),
		self.origin.x, self.origin.y
end

return Object
