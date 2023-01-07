local Camera = Object:extend()

Camera.transform = love.math.newTransform()

function Camera:new(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    rawset(self, "x", x)
    rawset(self, "y", y)
    rawset(self, "angle", 0)
    rawset(self, "zoom", 1)
end

function Camera:updateTransform(force)
    if force or self.currentCamera ~= self then
        Camera.currentCamera = self
        Camera.transform:reset()
        Camera.transform:translate(push.getWidth() * 0.5,
                                   push.getHeight() * 0.5)
        Camera.transform:translate(-self.x, -self.y)
    end
end

function Camera:getPosition(x, y) return Camera.transform:transformPoint(x, y) end

function Camera:attach()
    self:updateTransform()
    love.graphics.push()
    love.graphics.scale(self.zoom)
    love.graphics.rotate(-self.angle)
end

function Camera:detach() love.graphics.pop() end

function Camera:__newindex(k, v)
    local d = (k == "x" and v ~= self.x) or (k == "y" and v ~= self.y) or
                  (k == "angle" and v ~= self.angle) or
                  (k == "zoom" and v ~= self.zoom)
    rawset(self, k, v)
    if d then self:updateTransform(true) end
end

return Camera
