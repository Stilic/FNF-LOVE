local Camera = Object:extend()

Camera.__defaultCameras = {}

function Camera:new(x, y, width, height)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    if width == nil then width = 0 end
    if width <= 0 then width = push.getWidth() end
    if height == nil then height = 0 end
    if height <= 0 then height = push.getHeight() end
    self.x = x
    self.y = y
    self.scroll = {x = 0, y = 0}
    self.target = nil
    self.width = width
    self.height = height
    self.alpha = 1
    self.angle = 0
    self.zoom = 1
    self.visible = true
end

function Camera:update()
    if self.target then
        self.scroll.x, self.scroll.y = self.target.x - self.width * 0.5,
                                       self.target.y - self.height * 0.5
    end
end

function Camera:attach()
    love.graphics.push()
    love.graphics.rotate(-self.angle)
    local w, h = self.width * 0.5, self.height * 0.5
    love.graphics.translate(w - self.x, h - self.y)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-w, -h)
end

function Camera:detach() love.graphics.pop() end

return Camera