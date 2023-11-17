local function checkCollision(x1, y1, w1, h1, a, x2, y2, w2, h2, c)
    local rad = math.rad(a)

    local cos, sin = math.cos(rad), math.sin(rad)

    local to_screen = function(wx, wy)
        local x = (wx - c.scroll.x)
        local y = (wy - c.scroll.y)
        return x, y
    end

    x1, y1 = to_screen(x1, y1)
    x2, y2 = to_screen(x2, y2)

    local relativeX = x2 + w2 / 2 - (x1 + w1 / 2)
    local relativeY = y2 + h2 / 2 - (y1 + h1 / 2)

    return
        math.abs(relativeX * cos + relativeY * sin) -
            (w1 / (2 * c.zoom) + w2 / (2 * c.zoom)) < 0 and

        math.abs(-relativeX * sin + relativeY * cos) -
            (h1 / (2 * c.zoom) + h2 / (2 * c.zoom)) < 0
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

    local x1, y1 = camera.scroll.x, camera.scroll.y
    if self.scrollFactor ~= nil then
        x1, y1 = x1 * self.scrollFactor.x, y1 * self.scrollFactor.y
    end
    x1, y1 = ((self.x or 0) - x1) * camera.zoom,
             ((self.y or 0) - y1) * camera.zoom

    local w1, h1 = 0, 0
    if self:is(Text) then
        w1, h1 = self:getWidth(), self:getHeight()
    else
        w1, h1 = self.getFrameWidth and
                     (self:getFrameWidth() * math.abs(self.scale.x)) or
                     (self.width or 0),
                 self.getFrameHeight and
                     (self:getFrameHeight() * math.abs(self.scale.y)) or
                     (self.height or 0)
    end
    w1, h1 = w1 * camera.zoom, h1 * camera.zoom

    return checkCollision(x1, y1, w1, h1, self.angle or 0, camera.x * camera.zoom,
                          camera.y * camera.zoom, camera.width * camera.zoom,
                          camera.height * camera.zoom, camera)
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
