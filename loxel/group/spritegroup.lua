local _spriteGroup

local _ogSetColor
local function setColor(r, g, b, a)
	if type(r) == "table" then
		_ogSetColor(_spriteGroup:getMultColor(r[1], r[2], r[3], r[4]))
	else
		_ogSetColor(_spriteGroup:getMultColor(r, g, b, a))
	end
end

---@class SpriteGroup:Sprite
local SpriteGroup = Sprite:extend("SpriteGroup")

function SpriteGroup:new(x, y)
	SpriteGroup.super.new(self, x, y)

	self.group = Group()
	self.members = self.group.members

	self.__renderQueue = {}
end

local min, max, maxMember
function SpriteGroup:getWidth()
	if not next(self.members) then return 0 end

	min, max = 0, 0
	for _, member in pairs(self.members) do
		maxMember = member.x + member.width
		if maxMember > max then max = maxMember end
		if member.x < min then min = member.x end
	end

	self.width = max - min
	return self.width
end

function SpriteGroup:getHeight()
	if not next(self.members) then return 0 end

	min, max = 0, 0
	for _, member in pairs(self.members) do
		maxMember = member.y + member.height
		if maxMember > max then max = maxMember end
		if member.y < min then min = member.y end
	end

	self.height = max - min
	return self.height
end

function SpriteGroup:screenCenter(axes)
	self:getWidth(); self:getHeight()
	return SpriteGroup.super.screenCenter(self, axes)
end

function SpriteGroup:centerOffsets()
	self.offset.x, self.offset.y = 0, 0
end

function SpriteGroup:centerOrigin(__width, __height)
	self.origin.x = (__width or self:getWidth()) / 2
	self.origin.y = (__height or self:getHeight()) / 2
end

function SpriteGroup:draw()
	Sprite.super.draw(self) -- skips the Sprite:draw
	if not next(self.__cameraQueue) then return end

	local cameras, oldCameras = self.cameras or Camera.__defaultCameras
	for _, member in pairs(self.members) do
		oldCameras, member.cameras = member.cameras, cameras
		member:draw()
		member.cameras = oldCameras
		if next(member.__cameraQueue) then
			member:cancelDraw()
			table.insert(self.__renderQueue, member)
		end
	end
end

function SpriteGroup:__render(camera)
	if not next(self.__renderQueue) then return end
	local r, g, b, a = love.graphics.getColor()

	love.graphics.push()

	_spriteGroup = self
	_ogSetColor, love.graphics.setColor = love.graphics.setColor, setColor

	love.graphics.translate(self.x + self.origin.x + self.offset.x, self.y + self.origin.y + self.offset.y)
	love.graphics.scale(self.scale.x * self.zoom.x, self.scale.y * self.zoom.y)
	love.graphics.rotate(math.rad(self.angle))
	love.graphics.translate(-self.origin.x, -self.origin.y)

	local f
	for i, member in pairs(self.__renderQueue) do
		member:__render(camera)
		self.__renderQueue[i] = nil
	end

	love.graphics.pop()

	love.graphics.setColor = _ogSetColor

	love.graphics.setColor(r, g, b, a)
end

function SpriteGroup:updateHitbox() self:centerOffsets(); self:centerOrigin() end
function SpriteGroup:loadTexture() return self end
function SpriteGroup:setFrames() return self.__frames end

function SpriteGroup:update(dt) self.group:update(dt) end
function SpriteGroup:add(obj) return self.group:add(obj) end
function SpriteGroup:remove(obj) return self.group:remove(obj) end
function SpriteGroup:sort(func) return self.group:sort(func) end
function SpriteGroup:recycle(class, factory, revive) return self.group:recycle(class, factory, revive) end
function SpriteGroup:clear() self.group:clear() end
function SpriteGroup:kill() self.group:kill(); Sprite.super.kill(self) end
function SpriteGroup:revive() self.group:revive(); Sprite.super.revive(self) end
function SpriteGroup:destroy() self.group:destroy(); Sprite.super.destroy(self) end

return SpriteGroup
