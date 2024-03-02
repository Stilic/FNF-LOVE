---@class SpriteGroup:Sprite
local SpriteGroup = Sprite:extend("SpriteGroup")

function SpriteGroup:new(x, y)
	SpriteGroup.super.new(self, x, y)

	self.group = Group()
	self.members = self.group.members

	self.__renderQueue = {}

	self:__initializeDrawFunctions()
end

-- personally, dont use width, height, or origin if you plan to use "dynamic" scrollFactors
function SpriteGroup:__getNestDimension(members)
	local xmin, xmax, ymin, ymax, x, y, width, height = 0, 0, 0, 0
	for _, member in ipairs(members) do
		if member.x then
			x, y = member.x, member.y
			width = x + (member.getWidth and member:getWidth() or member.width)
			height = y + (member.getHeight and member:getHeight() or member.height)
		elseif member.members then
			x, width, y, height = self:__getNestDimension(member.members)
		end
		if width > xmax then xmax = width end
		if x < xmin then xmin = x end
		if height > ymax then ymax = height end
		if y < ymin then ymin = y end
	end
	return xmin, xmax, ymin, ymax
end

function SpriteGroup:getWidth()
	if not next(self.members) then return 0 end

	local xmin, xmax, ymin, ymax = self:__getNestDimension(self.members)
	self.width, self.height = xmax - xmin, ymax - ymin
	return self.width
end

function SpriteGroup:getHeight()
	if not next(self.members) then return 0 end

	local xmin, xmax, ymin, ymax = self:__getNestDimension(self.members)
	self.width, self.height = xmax - xmin, ymax - ymin
	return self.height
end

function SpriteGroup:screenCenter(axes)
	self:getWidth()
	return SpriteGroup.super.screenCenter(self, axes)
end

function SpriteGroup:centerOffsets()
	self.offset.x, self.offset.y = 0, 0
end

function SpriteGroup:centerOrigin(__width, __height)
	self:getWidth()
	self.origin.x = (__width or self.width) / 2
	self.origin.y = (__height or self.height) / 2
end

function SpriteGroup:__drawNestGroup(members)
	for _, member in ipairs(members) do
		if member:_canDraw() then
			if member.__render then
				table.insert(self.__renderQueue, member)
			elseif member.members then
				self:__drawNestGroup(member.members)
			end
		end
	end
end

function SpriteGroup:_canDraw()
	table.clear(self.__renderQueue)

	-- skips the Sprite check
	if Sprite.super._canDraw(self) and self:isOnScreen(self.cameras or Camera.__defaultCameras) then
		self:__drawNestGroup(self.members)
		return next(self.__renderQueue) ~= nil
	end
end

function SpriteGroup:__render(camera)
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()

	self.__ogSetColor, love.graphics.setColor = love.graphics.setColor, self.__setColor

	love.graphics.translate(self.x + self.origin.x + self.offset.x, self.y + self.origin.y + self.offset.y)
	love.graphics.scale(self.scale.x * self.zoom.x, self.scale.y * self.zoom.y)
	love.graphics.rotate(math.rad(self.angle))
	love.graphics.translate(-self.origin.x, -self.origin.y)

	local a, b = camera.scroll, self.scrollFactor
	for i, member in ipairs(self.__renderQueue) do
		if member.x then
			love.graphics.push()
			love.graphics.translate(a.x * member.scrollFactor.x * (1 - b.x), a.y * member.scrollFactor.y * (1 - b.y))
			member:__render(camera)
			love.graphics.pop()
		else
			member:__render(camera)
		end
		self.__renderQueue[i] = nil
	end

	love.graphics.pop()

	love.graphics.setColor = self.__ogSetColor

	love.graphics.setColor(cr, cg, cb, ca)
end

function SpriteGroup:__initializeDrawFunctions()
	function self.__setColor(r, g, b, a)
		if type(r) == "table" then
			self.__ogSetColor(self:getMultColor(r[1], r[2], r[3], r[4]))
		else
			self.__ogSetColor(self:getMultColor(r, g, b, a))
		end
	end
end

function SpriteGroup:updateHitbox()
	self:centerOffsets(); self:centerOrigin()
end

function SpriteGroup:loadTexture() return self end

function SpriteGroup:setFrames() return self.__frames end

function SpriteGroup:update(dt) self.group:update(dt) end

function SpriteGroup:add(obj) return self.group:add(obj) end

function SpriteGroup:remove(obj) return self.group:remove(obj) end

function SpriteGroup:sort(func) return self.group:sort(func) end

function SpriteGroup:recycle(class, factory, revive) return self.group:recycle(class, factory, revive) end

function SpriteGroup:clear() self.group:clear() end

function SpriteGroup:kill()
	self.group:kill(); Sprite.super.kill(self)
end

function SpriteGroup:revive()
	self.group:revive(); Sprite.super.revive(self)
end

function SpriteGroup:destroy()
	self.group:destroy(); Sprite.super.destroy(self)
end

return SpriteGroup
