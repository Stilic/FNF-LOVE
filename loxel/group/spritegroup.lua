-- Children Function
local function tranformChildren(self, func, value)
    if self.group == nil then return end

    for _, sprite in ipairs(self.__sprites) do
        if sprite ~= nil then func(sprite, value) end
    end
end

local function xTransform(sprite, x) sprite.x = sprite.x + x end
local function yTransform(sprite, y) sprite.y = sprite.y + y end
local function angleTransform(sprite, angle) sprite.angle = sprite.angle + angle end
local function alphaTransform(sprite, alpha) sprite.alpha = alpha end
local function flipXTransform(sprite, flipX) sprite.flipX = flipX end
local function flipYTransform(sprite, flipY) sprite.flipY = flipY end
local function colorTransform(sprite, color) sprite.color = color end
local function visibleTransform(sprite, visible) sprite.visible = visible end
local function aliveTransform(sprite, alive) sprite.alive = alive end
local function existsTransform(sprite, exists) sprite.exists = exists end
local function camerasTransform(sprite, cameras) sprite.cameras = cameras end
local function offsetTransform(sprite, offset) sprite.offset = offset end
local function originTransform(sprite, origin) sprite.origin = origin end
local function scaleTransform(sprite, scale) sprite.scale = scale end
local function scrollFactorTransform(sprite, scrollFactor)
    sprite.scrollFactor = scrollFactor
end
local function clipRectTransform(sprite, clipRect, self)
    if clipRect == nil then
        sprite.clipRect = nil
    else
        sprite.clipRect.x = clipRect.x - sprite.x + self.x
        sprite.clipRect.y = clipRect.y - sprite.y + self.y
        sprite.clipRect.width = clipRect.width
        sprite.clipRect.height = clipRect.height
    end
end

--------------

---@class SpriteGroup:Sprite
local SpriteGroup = Sprite:extend("SpriteGroup")

function SpriteGroup:new(x, y)
    SpriteGroup.super.new(self, x, y)

    self.__x = self.x
    self.__y = self.y

    self.__cameras = self.cameras

    self.__alive = self.alive
    self.__exists = self.exists

    self.__origin = self.origin
    self.__offset = self.offset
    self.__scale = self.scale
    self.__scrollFactor = self.scrollFactor
    self.__clipRect = self.clipRect
    self.__flipX = self.flipX
    self.__flipY = self.flipY

    self.__visible = self.visible
    self.__color = self.color
    self.__alpha = self.alpha
    self.__angle = self.angle

    self.group = Group()
    self.__sprites = self.group.members
end

function SpriteGroup:update(dt)
    if self.__cameras ~= self.cameras then
        tranformChildren(self, camerasTransform, self.cameras)
        self.__cameras = self.cameras
    end
    if self.__exists ~= self.exists then
        tranformChildren(self, existsTransform, self.exists)
        self.__exists = self.exists
    end
    if self.__visible ~= self.visible then
        if self.exists then
            tranformChildren(self, visibleTransform, self.visible)
            self.__visible = self.visible
        end
    end
    if self.__alive ~= self.alive then
        if self.exists then
            tranformChildren(self, aliveTransform, self.alive)
            self.__alive = self.alive
        end
    end
    if self.__x ~= self.x then
        if self.exists then
            tranformChildren(self, xTransform, self.x - self.__x)
            self.__x = self.x
        end
    end
    if self.__y ~= self.y then
        if self.exists then
            tranformChildren(self, yTransform, self.y - self.__y)
            self.__y = self.y
        end
    end
    if self.__angle ~= self.angle then
        if self.exists then
            tranformChildren(self, angleTransform, self.angle - self.__angle)
            self.__angle = self.angle
        end
    end
    if self.__alpha ~= self.alpha then
        if self.exists then
            tranformChildren(self, alphaTransform, self.alpha)
            self.__alpha = self.alpha
        end
    end
    if self.__flipX ~= self.flipX then
        if self.exists then
            tranformChildren(self, flipXTransform, self.flipX)
            self.__flipX = self.flipX
        end
    end
    if self.__flipY ~= self.flipY then
        if self.exists then
            tranformChildren(self, flipYTransform, self.flipY)
            self.__flipY = self.flipY
        end
    end
    if self.__color ~= self.color then
        if self.exists then
            tranformChildren(self, colorTransform, self.color)
            self.__color = self.color
        end
    end
    if self.__clipRect ~= self.clipRect then
        if self.exists then
            tranformChildren(self, clipRectTransform, self.clipRect, self)
            self.__clipRect = self.clipRect
        end
    end
    if self.__origin ~= self.origin then
        if self.exists then
            tranformChildren(self, originTransform, self.origin)
            self.__origin = self.origin
        end
    end
    if self.__offset ~= self.offset then
        if self.exists then
            tranformChildren(self, offsetTransform, self.offset)
            self.__offset = self.offset
        end
    end
    if self.__scale ~= self.scale then
        if self.exists then
            tranformChildren(self, scaleTransform, self.scale)
            self.__scale = self.scale
        end
    end
    if self.__scrollFactor ~= self.scrollFactor then
        if self.exists then
            tranformChildren(self, scrollFactorTransform, self.scrollFactor)
            self.__scrollFactor = self.scrollFactor
        end
    end

    self.group:update(dt)
end

function SpriteGroup:draw() self.group:draw() end

function SpriteGroup:add(sprite)
    self:preAdd(sprite)
    return self.group:add(sprite)
end

function SpriteGroup:preAdd(sprite)
    local spr = sprite
    spr.x = spr.x + self.x
    spr.y = spr.y + self.y
    spr.alpha = spr.alpha * self.alpha
    spr.scrollFactor = self.scrollFactor
    spr.cameras = self.cameras

    if self.clipRect ~= nil then clipRectTransform(spr, self.clipRect, self) end
end

function SpriteGroup:recycle(class, factory, revive)
    return self.group:recycle(class, factory, revive)
end

function SpriteGroup:remove(sprite)
    local spr = sprite
    spr.x = spr.x - self.x
    spr.y = spr.y - self.y
    spr.cameras = nil
    return self.group:remove(sprite)
end

function SpriteGroup:sort(func) self.group:sort(func) end

function SpriteGroup:getWidth()
    if #self.group.members == 0 then return 0 end

    local minX = 0
    local maxX = 0
    for _, member in ipairs(self.__sprites) do
        if member ~= nil then
            local minMemberX = member.x
            local maxMemberX = minMemberX + member.width

            if maxMemberX > maxX then maxX = maxMemberX end
            if minMemberX < minX then minX = minMemberX end
        end
    end
    return (maxX - minX) - self.x
end

function SpriteGroup:getHeight()
    if #self.group.members == 0 then return 0 end

    local minY = 0
    local maxY = 0
    for _, member in ipairs(self.__sprites) do
        if member ~= nil then
            local minMemberY = member.y
            local maxMemberY = minMemberY + member.height

            if maxMemberY > maxY then maxY = maxMemberY end
            if minMemberY < minY then minY = minMemberY end
        end
    end
    return (maxY - minY) - self.y
end

function SpriteGroup:screenCenter(axes)
    if axes == nil then axes = "xy" end
    if axes:find("x") then self.x = (game.width - self:getWidth()) * 0.5 end
    if axes:find("y") then self.y = (game.height - self:getHeight()) * 0.5 end
    return self
end

-- Not Supported

function SpriteGroup:loadTexture() return self end

function SpriteGroup:setFrames() return self.__frames end

return SpriteGroup
