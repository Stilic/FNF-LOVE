local Camera = Object:extend()

function Camera:new(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    self.x = x
    self.y = y
    self.angle = 0
    self.zoom = 1
end

function Camera:getPosition(x, y)
    return x - self.x + push.getWidth() * 0.5,
           y - self.y + push.getHeight() * 0.5
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
    love.graphics.push()

    local w2, h2 = push.getWidth() * 0.5, push.getHeight() * 0.5
    love.graphics.scale(self.zoom)
    love.graphics.translate(w2 / self.zoom - w2, h2 / self.zoom - h2)
    love.graphics.translate(w2, h2)
    love.graphics.rotate(-self.angle)
    love.graphics.translate(-w2, -h2)
end

function Camera:detach() love.graphics.pop() end

return Camera
