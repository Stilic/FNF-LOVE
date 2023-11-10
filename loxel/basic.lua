local function checkCollision(x1, y1, w1, h1, a1, x2, y2, w2, h2)
    local cos1 = math.cos(a1)
    local sin1 = math.sin(a1)

    local relativeX = (x2 + w2 / 2) - (x1 + w1 / 2)
    local relativeY = (y2 + h2 / 2) - (y1 + h1 / 2)

    return
        math.abs(relativeX * cos1 + relativeY * sin1) - (w1 / 2 + w2 / 2) < 0 and
            math.abs(-relativeX * sin1 + relativeY * cos1) - (h1 / 2 + h2 / 2)
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
    x1, y1 = x1 * camera.zoom, y1 * camera.zoom

    local x2, y2 = self.x or 0, self.y or 0
    x2, y2 = x2 * camera.zoom, y2 * camera.zoom

    local w1, h1 = camera.width * camera.zoom,
                   camera.height * camera.zoom

    local w2, h2 = self.width or 0, self.height or 0
    if self:is(Text) then
        w2, h2 = self:getWidth(), self:getHeight()
    end
    w2, h2 = w2 * camera.zoom, h2 * camera.zoom

    return checkCollision(x1, y1, w1, h1, 0, x2, y2, w2, h2)
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
