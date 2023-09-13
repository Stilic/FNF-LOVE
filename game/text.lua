local Text = Object:extend()

function Text:new(x, y, content, font, color, align, outlined, limit)
    self.x = x or 0
    self.y = y or 0
    self.content = content or ""
    self.font = font or love.graphics.getFont()
    self.size = size or 1
    self.color = color or {1, 1, 1}
    self.cameras = nil
    self.alignment = align or "left"
    self.limit = limit

    self.outColor = {0, 0, 0}
    self.outWidth = 0
end

function Text:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function Text:setContent(content) self.content = content or "" end

function Text:getWidth() return self.font:getWidth(self.content) end

function Text:getHeight() return self.font:getHeight(self.content) end

function Text:setFont(font) self.font = font or love.graphics.getFont() end

function Text:setColor(color) self.color = color or {1, 1, 1} end

function Text:screenCenter(axes)
    if axes == nil then axes = "xy" end

    if axes:find("x") then
        self.x = (push.getWidth() - self.font:getWidth(self.content)) * 0.5
    end
    if axes:find("y") then
        self.y = (push.getHeight() - self.font:getHeight(self.content)) * 0.5
    end
end

function Text:draw()
    local ogFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setFont(self.font)

    for _, cam in ipairs(self.cameras or Camera.defaultCameras) do
        love.graphics.setColor(self.outColor)

        cam:attach()
        if self.outWidth > 0 then
            for dx = -self.outWidth, self.outWidth do
                for dy = -self.outWidth, self.outWidth do
                    love.graphics.printf(self.content, self.x + dx, self.y + dy,
                                         (self.limit or self:getWidth()),
                                         self.alignment)
                end
            end
        end

        love.graphics.setColor(self.color)
        love.graphics.printf(self.content, self.x, self.y,
                             (self.limit or self:getWidth()), self.alignment)

        cam:detach()
    end

    love.graphics.setFont(ogFont)
    love.graphics.setColor(r, g, b, a)
end

return Text
