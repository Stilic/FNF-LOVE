-- cod3e cancer

--[[local function checkCollision(...)
	
end]]

local Actor = Object:extend("Actor")

function Actor:new(x, y, z)
	Actor.super.new(self)

	self.z = z or 1
	self.depth = 0 -- i guess you can call this the size for z axis??

	self.offset.z = 0
	self.origin.z = 0
	self.scale.z = 1
	self.zoom.z = 1
 
	self.moves = false
	self.velocity.z = 0
	self.acceleration.z = 0
end

function Actor:destroy()
	Actor.super.destroy(self)

	self.offset.x, self.offset.y, self.offset.z = 0, 0, 0
	self.scale.x, self.scale.y, self.offset.z = 1, 1, 1

	self.shader = nil
end

function Actor:setPosition(x, y, z)
	self.x, self.y, self.z = x or 0, y or 0, z or 0
end

function Actor:setScrollFactor(x, y, z)
	self.scrollFactor.x, self.scrollFactor.y, self.scrollFactor.z = x or 0, y or x or 0, z or 0
end

function Actor:getMidpoint()
	return self.x + self.width / 2, self.y + self.height / 2, self.z + self.depth / 2
end

function Actor:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.width) / 2 end
	if axes:find("y") then self.y = (game.height - self.height) / 2 end
	if axes:find("z") then self.z = self.depth / 2 end
	return self
end

function Actor:updateHitbox()
	local width, height, depth
	if self.getDepth then
		width, height, depth = self:getWidth(), self:getHeight(), self:getDepth()
	end
	self:fixOffsets(width, height)
	self:centerOrigin(width, height)
end

function Actor:centerOffsets(__width, __height, __depth)
	self.offset.x = (__width or self.width) / 2
	self.offset.y = (__height or self.height) / 2
	self.offset.z = (__depth or self.depth) / 2
end

function Actor:fixOffsets(__width, __height, __depth)
	self.offset.x = ((__width or self.width) - self.width) / 2
	self.offset.y = ((__height or self.height) - self.height) / 2
	self.offset.z = ((__depth or self.depth) - self.depth) / 2
end

function Actor:centerOrigin(__width, __height, __depth)
	self.origin.x = (__width or self.width) / 2
	self.origin.y = (__height or self.height) / 2
	self.origin.z = (__depth or self.depth) / 2
end

function Actor:update(dt)
	if self.moves then
		self.velocity.x = self.velocity.x + self.acceleration.x * dt
		self.velocity.y = self.velocity.y + self.acceleration.y * dt
		self.velocity.z = self.velocity.z + self.acceleration.z * dt

		self.x = self.x + self.velocity.x * dt
		self.y = self.y + self.velocity.y * dt
		self.z = self.z + self.velocity.z * dt
	end
end

function Actor:_isOnScreen(c, ...)
	return true
end

function Actor:isOnScreen(cameras)
	return true
end

-- these fuckers that handles everything
function Actor:toScreen(x, y, z, fov)
	local hw, hh = game.width / 2, game.height / 2
	return
		hw + ((x - hw) / z) * fov,
		hh + ((y - hh) / z) * fov,
		(1 / z) * fov
end

local rad, fastcos, fastsin = math.rad, math.fastcos, math.fastsin
function Actor:worldSpin(x, y, z, ax, ay, az, midx, midy, midz)
	local radx, rady, radz = rad(ax), rad(ay), rad(az)
	local angx1, angx2, angy1, angy2, angz1, angz2 = fastcos(radx), fastsin(radx), fastcos(rady), fastsin(rady), fastcos(radz), fastsin(radz)
	local gapx, gapy, gapz = x - midx, midy - y, midz - z

	local nx = midx
		+ angy0 * angz0 * gapx + (-angz1 * angx0 + angx1 * angy1 * angz0) * gapy + (angx1 * angz1 + angx0 * angy1 * angz0) * gapz
	local ny = midy
		- angy0 * angz0 * gapx - (angx1 * angz0 + angx1 * angy1 * angz0) * gapy - (-angx1 * angz1 + angx0 * angy1 * angz0) * gapz
	local nz = midz + angy1 * gapx - angx1 * angy0 * gapy - angx0 * angy0 * gapz

	return nx, ny, nz
end

function Actor:multiWorldSpin(x, y, z, ax, ay, az, midx, midy, midz)
	local nx, ny, nz = self:worldSpin(x, y, z, ax[1], ay[1], az[1], midx[1], midy[1], midz[1])
	for i = 2, #ax do nx, ny, nz = self:worldSpin(nx, ny, nz, ax[i], ay[i], az[i], midx[i], midy[i], midz[i]) end
	return nx, ny, nz
end

function Actor:_getBoundary()
	return
end

return Actor
