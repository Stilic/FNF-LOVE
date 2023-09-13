local Camera = Object:extend()

function Camera:new(x, y, width, height)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    if width == nil then width = 0 end
    if width <= 0 then width = push.getWidth() end
    if height == nil then height = 0 end
    if height <= 0 then height = push.getHeight() end
    self.x = x
    self.y = y
    self.target = nil
    self.width = width
    self.height = height
    self.alpha = 1
    self.angle = 0
    self.zoom = 1
end

function Camera:getPosition(x, y)
    return x - (self.target == nil and 0 or self.target.x) + self.width * 0.5,
           y - (self.target == nil and 0 or self.target.y) + self.height * 0.5
end

function Camera:attach()
    love.graphics.push()
    love.graphics.rotate(-self.angle)
    local w = self.width / 2
    local h = self.height / 2
    love.graphics.translate(w - self.x, h - self.y)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-w, -h)
end

function Camera:detach() love.graphics.pop() end

return Camera
