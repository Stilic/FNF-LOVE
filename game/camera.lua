local Camera = Object:extend()

Camera.transform = love.math.newTransform()

function Camera:new(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    self.x = x
    self.y = y
    self.angle = 0
    self.zoom = 1
end

function Camera:getLocalPosition(x, y, sx, sy)
    if sx == nil then sx = 1 end
    if sy == nil then sy = 1 end

    Camera.transform:reset()
    Camera.transform:translate(push.getWidth() * 0.5 / self.zoom,
                               push.getHeight() * 0.5 / self.zoom)
                               local x2, y2 = self.x * 0.5, self.y * 0.5
    Camera.transform:translate(-x2 * self.zoom - self.x,
                               -y2 * self.zoom - self.y)

    local tx, ty = Camera.transform:transformPoint(x, y)
    return util.lerp(x, tx, sx), util.lerp(y, ty, sy)
end

function Camera:attach()
    love.graphics.push()
    love.graphics.scale(self.zoom)
    -- love.graphics.rotate(-self.angle)
end

function Camera:detach() love.graphics.pop() end

return Camera
