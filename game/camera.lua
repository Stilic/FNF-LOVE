local Camera = Object:extend()

Camera.transform = love.math.newTransform()
Camera.currentCamera = nil

function Camera:new(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    rawset(self, "x", x)
    rawset(self, "y", y)
    self.angle = 0
    self.zoom = 1
end

function Camera:updateTransform(force)
    if force or
        (Camera.currentCamera ~= self and (Camera.currentCamera == nil or
            (Camera.currentCamera.x ~= self.x and Camera.currentCamera.y ~= y))) then
        Camera.currentCamera = self
        Camera.transform:reset()
        Camera.transform:translate(push.getWidth() * 0.5, push.getHeight() * 0.5)
        Camera.transform:translate(-self.x, -self.y)
    end
end

function Camera:getPosition(x, y)
    self:updateTransform()
    return Camera.transform:transformPoint(x, y)
end

function Camera:getObjectPosition(obj)
    local tx, ty = self:getPosition(0, 0)
    if obj.scrollFactor then
        tx = tx * obj.scrollFactor.x
        ty = ty * obj.scrollFactor.y
    end
    return obj.x + tx, obj.y + ty
end

function Camera:attach()
    self:updateTransform()
    love.graphics.push()

    local w2, h2 = push.getWidth() * 0.5, push.getHeight() * 0.5
    love.graphics.scale(self.zoom)
    love.graphics.translate(w2, h2)
    love.graphics.translate(w2 / self.zoom - w2, h2 / self.zoom - h2)
    love.graphics.rotate(-self.angle)
    love.graphics.translate(-w2, -h2)
end

function Camera:detach() love.graphics.pop() end

function Camera:__newindex(k, v)
    local d = (k == "x" and v ~= self.x) or (k == "y" and v ~= self.y)
    rawset(self, k, v)
    if d then self:updateTransform(true) end
end

return Camera
