local Button = Basic:extend()

function Button:new(x, y, width, height, text, callback)
    Button.super.new(self)

    self.x = x or 0
    self.y = y or 0
    self.width = width or 80
    self.height = height or 20
    self.text = text or "Button"
    self.hovered = false
    self.font = love.graphics.getFont()
    self.font:setFilter("nearest", "nearest")
    self.callback = callback
    self.color = {0.5, 0.5, 0.5}
    self.textColor = {1, 1, 1}
end

function Button:update(dt)
    local mx, my = Mouse.x, Mouse.y
    self.hovered =
        (mx >= self.x and mx <= self.x + self.width and my >= self.y and my <=
            self.y + self.height)
end

function Button:__render()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    if self.hovered then
        love.graphics.setColor(0.2, 0.2, 0.2)
    else
        love.graphics.setColor(0, 0, 0)
    end
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    local textX = self.x + (self.width - self.font:getWidth(self.text)) / 2
    local textY = self.y + (self.height - self.font:getHeight()) / 2

    love.graphics.setColor(self.textColor)
    love.graphics.print(self.text, textX, textY)
    love.graphics.setColor(r, g, b, a)

    love.graphics.setColor(r, g, b, a)
end

function Button:mousepressed(x, y, button, istouch, presses)
    if self.hovered and self.callback then self.callback() end
end

return Button
