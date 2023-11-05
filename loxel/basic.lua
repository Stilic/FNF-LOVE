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
    return checkCollision(0, 0, camera.width * camera.zoom,
                          camera.height * camera.zoom, 0, self.x, self.y,
                          self.width or 0, self.height or 0, self.angle or 0)
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
