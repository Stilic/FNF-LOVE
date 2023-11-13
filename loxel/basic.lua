local function checkCollision(x1, y1, w1, h1, a, x2, y2, w2, h2, c)
local function checkCollision(x1, y1, w1, h1, a, x2, y2, w2, h2, c)
    local rad = math.rad(a)
    local zoom = (math.abs(c.zoom) < 1 and 2 * c.zoom or 2 / c.zoom)
    local cos, sin = math.cos(rad), math.sin(rad)

    local relativeX = (x2 + w2 / 2) - (x1 + w1 / 2)
    local relativeY = (y2 + h2 / 2) - (y1 + h1 / 2)

    return
        math.abs(relativeX * cos + relativeY * sin) -
            (w1 / zoom + w2 / zoom) < 0 and

        math.abs(-relativeX * sin + relativeY * cos) -
            (h1 / zoom + h2 / zoom) < 0
end

---@class Basic:Object
local Basic = Object:extend()

function Basic:new()
    self.active = true
    self.visible = true

    self.alive = true
    self.exists = true

    self.cameras = nil
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

function Basic:isOnScreen(camera)
    camera = camera or game.camera

    local x, y, ox, oy = camera.scroll.x, camera.scroll.y, 0, 0
    if self.scrollFactor ~= nil then
        x, y = x * self.scrollFactor.x, y * self.scrollFactor.y
    end
    if self.offset ~= nil then
        ox, oy = ox - self.offset.x, oy - self.offset.y
    end
    if self.getCurrentFrame then
        local f = self:getCurrentFrame()
        if f then
          ox, oy = ox - f.offset.x, oy - f.offset.y
        end
    end
    x, y = ((self.x or 0) - ox - x),
             ((self.y or 0) - ox - y)

    local w, h = 0, 0
    if self:is(Text) then
        w, h = self:getWidth(), self:getHeight()
    else
        w, h = self.getFrameWidth and
                     (self:getFrameWidth() * math.abs(self.scale.x)) or
                     (self.width or 0),
                 self.getFrameHeight and
                     (self:getFrameHeight() * math.abs(self.scale.y)) or
                     (self.height or 0)
    end

    return checkCollision(x, y, w, h, self.angle or 0, camera.x,
                          camera.y, camera.width,
                          camera.height, camera)
end

function Basic:draw()
    if self.__render then
        for _, c in ipairs(self.cameras or Camera.__defaultCameras) do
            if c.visible and c.exists and self:isOnScreen(c) then
                table.insert(c.__renderQueue, self)
            end
        end
    end
end

return Basic
