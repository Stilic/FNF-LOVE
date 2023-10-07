local Bar = Object:extend()

function Bar:new(x, y, width, height, maxValue, color, filledBar, opColor)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 100
    self.height = height or 20
    self.maxValue = maxValue or 100
    self.value = self.maxValue
    self.color = color or {255, 0, 0}
    self.opColor = opColor or {0, 255, 0}
    self.flipX = false
    self.filledBar = filledBar or false
    self.cameras = nil
    self.fillWidth = self.width - ((self.value / self.maxValue) * self.width)
    self.percent = (self.value / self.maxValue) * 100
end

function Bar:setValue(value)
    self.value = math.min(math.max(value, 0), self.maxValue)
end

function Bar:screenCenter(axes)
    if axes == nil then axes = "xy" end
    if axes:find("x") then self.x = (game.width - self.width) * 0.5 end
    if axes:find("y") then self.y = (game.height - self.height) * 0.5 end
    return self
end

function Bar:update()
    self.fillWidth = self.width - ((self.value / self.maxValue) * self.width)
    self.percent = (self.value / self.maxValue) * 100
end

function Bar:draw()
    local r, g, b, a = love.graphics.getColor()

    for _, c in ipairs(self.cameras or Camera.__defaultCameras) do
        if c.visible and c.exists then
            table.insert(c.__renderQueue, self)
        end
    end

    love.graphics.setColor(r, g, b, a)
end

function Bar:__render(camera)
    if self.filledBar then
        love.graphics.setColor(self.flipX and self.color or self.opColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end

    love.graphics.setColor(self.flipX and self.opColor or self.color)
    love.graphics.rectangle("fill", self.x - camera.scroll.x,
                            self.y - camera.scroll.y, self.fillWidth,
                            self.height)
end

return Bar
