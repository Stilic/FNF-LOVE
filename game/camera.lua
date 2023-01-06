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

function Camera:getTargetPosition(x, y)
    if sx == nil then sx = 1 end
    if sy == nil then sy = 1 end

    Camera.transform:reset()
    Camera.transform:scale(self.zoom)
    Camera.transform:translate(push.getWidth() * 0.5,
                               push.getHeight() * 0.5)
    Camera.transform:rotate(-self.angle)
    Camera.transform:translate(-self.x, -self.y)

    return Camera.transform:transformPoint(x, y)
end

return Camera
