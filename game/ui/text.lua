local Text = Object:extend()

function Text:new(x, y, text, font)
    self.font = font or love.graphics.getFont()
    self.font:setFilter("nearest", "nearest")
    self.text = text
    self.x = x or 0
    self.y = y or 0
    self.color = {1, 1, 1}

    self.cameras = nil
end

function Text:draw()
    local cameras = self.cameras or Camera.__defaultCameras
    for _, cam in ipairs(cameras) do
        cam:attach()

        local r, g, b, a = love.graphics.getColor()

        love.graphics.setColor(self.color)
        love.graphics.setFont(self.font)
        love.graphics.print(self.text, self.x, self.y)

        love.graphics.setColor(r, g, b, a)

        cam:detach()
    end
end

return Text
