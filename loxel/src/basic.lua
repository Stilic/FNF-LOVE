-- this should get a rework, also it isnt supposed to be in this script
local function checkCollision(x1, y1, w1, h1, a, x2, y2, w2, h2, zx, zy)
	local rad = math.rad(a)
	local cos, sin = math.cos(rad), math.sin(rad)

	local relativeX = (x2 + w2 / 2) - (x1 + w1 / 2)
	local relativeY = (y2 + h2 / 2) - (y1 + h1 / 2)

	return
		math.abs(relativeX * cos + relativeY * sin) - (w1 / zx + w2 / zx) < 0 and
		math.abs(-relativeX * sin + relativeY * cos) - (h1 / zy + h2 / zy) < 0
end

-----------------------------------------------------------------------------------------------
local source = (...) and (...):gsub('%.basic$', '.') or ""
local Classic = require(source .. "lib.classic")

---@class Basic:Classic
local Basic = Classic:extend("Basic")

function Basic:new()
	self.active = true
	self.visible = true

	self.alive = true
	self.exists = true

	self.cameras = nil
	self.__cameraQueue = {}
end

function Basic:kill()
	self.alive = false
	self.exists = false
end

function Basic:revive()
	self.alive = true
	self.exists = true
end

function Basic:destroy()
	self.exists = false
	self.cameras = nil
end

function Basic:isOnScreen(cameras)
	if not self.scale then return true end

	local x, y = self.x or 0, self.y or 0
	if self.offset ~= nil then x, y = x + self.offset.x, y + self.offset.y end
	if self.getCurrentFrame then
		local f = self:getCurrentFrame()
		if f then x, y = x + f.offset.x, y + f.offset.y end
	end

	local w, h = math.abs(self.scale.x * self.zoom.x), math.abs(self.scale.y * self.zoom.y)
	if self.getWidth then
		w, h = self:getWidth() * w, self:getHeight() * h
	else
		w, h = (self.getFrameWidth and self:getFrameWidth() or self.width or 0) * w,
			(self.getFrameHeight and self:getFrameHeight() or self.height or 0) * h
	end

	if cameras.x then
		if self.scrollFactor ~= nil then
			x, y = x - cameras.scroll.x * self.scrollFactor.x,
				y - cameras.scroll.y * self.scrollFactor.y
		else
			x, y = x - cameras.scroll.x, y - cameras.scroll.y
		end
		return checkCollision(x, y, w, h, self.angle or 0, cameras.x, cameras.y,
			cameras.width, cameras.height, cameras.__zoom.x, cameras.__zoom.y)
	else
		local x2, y2
		for _, c in pairs(cameras) do
			if self.scrollFactor ~= nil then
				x2, y2 = x - c.scroll.x * self.scrollFactor.x,
					y - c.scroll.y * self.scrollFactor.y
			else
				x2, y2 = x - c.scroll.x, y - c.scroll.y
			end
			if checkCollision(x2, y2, w, h, self.angle or 0, c.x, c.y, c.width, c.height,
					c.__zoom.x, c.__zoom.y)
			then
				return true
			end
		end
	end
	return false
end

function Basic:_canDraw()
	return self.__render and self.visible and self.exists
end

function Basic:canDraw()
	return self:_canDraw() and self:isOnScreen(self.cameras or
		(require(source .. "camera")).__defaultCameras)
end

function Basic:draw()
	if self:_canDraw() then
		for _, c in pairs(self.cameras or
			(require(source .. "camera")).__defaultCameras) do
			if c.visible and c.exists and self:isOnScreen(c) then
				table.insert(c.__renderQueue, self)
				table.insert(self.__cameraQueue, c)
			end
		end
	end
end

function Basic:cancelDraw()
	for i, c in pairs(self.__cameraQueue) do
		for i = #c.__renderQueue, 1, -1 do
			if c.__renderQueue[i] == self then
				table.remove(c.__renderQueue, i)
				break
			end
		end
		self.__cameraQueue[i] = nil
	end
end

--function Basic:enter(group) end
--function Basic:leave(group) end
--function Basic:resume(group) end

return Basic
