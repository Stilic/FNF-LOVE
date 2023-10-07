local Checkbox = Object:extend()

function Checkbox:new(x, y, size, callback)
    self.x = x or 0
    self.y = y or 0
    self.size = size or 20
    self.checked = false
    self.hovered = false
    self.callback = callback
    self.cameras = nil
end

function Checkbox:update(dt)
    local mx, my = Mouse.x, Mouse.y
    self.hovered =
        (mx >= self.x and mx <= self.x + self.size and my >= self.y and my <=
            self.y + self.size)
end

function Checkbox:draw()
    for _, c in ipairs(self.cameras or Camera.__defaultCameras) do
        if c.visible and c.exists then
            table.insert(c.__renderQueue, self)
        end
    end
end

function Checkbox:__render()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)

    if self.hovered then
        love.graphics.setColor(0.2, 0.2, 0.2)
    else
        love.graphics.setColor(0, 0, 0)
    end

    love.graphics.rectangle("line", self.x, self.y, self.size, self.size)

    if self.checked then
        love.graphics.push()

        local checkX = self.x + self.size / 2
        local checkY = self.y + self.size / 2

        love.graphics.translate(checkX, checkY)
        love.graphics.setColor(0, 0, 0)

        local logo_position = {(-self.size) * 0.3, (-self.size) * -0.3}

        love.graphics.rotate(math.rad(45))
        love.graphics.rectangle("fill", logo_position[1], logo_position[2],
                                (self.size * 0.5), (self.size * 0.2))
        love.graphics.rectangle("fill", 0, logo_position[2] * -2,
                                (self.size * 0.2), (self.size * 1.1))

        love.graphics.pop()
    end

    love.graphics.setColor(r, g, b, a)
end

function Checkbox:mousepressed(x, y, button, istouch, presses)
    if self.hovered then
        self.checked = not self.checked
        if self.callback then self.callback() end
    end
end

return Checkbox
