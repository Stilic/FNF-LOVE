local Text = Object:extend()

function Text:new(x, y, content, font, color, align, limit)
    self.x = x or 0
    self.y = y or 0

    self.content = content
    self.font = font or love.graphics.getFont()
    self.alignment = align or "left"
    self.limit = limit

    self.color = color or {1, 1, 1}
    self.alpha = 1
    self.cameras = nil
    self.visible = true

    self.exists = true

    self.antialiasing = true
    self.blend = "alpha"
    self.shader = nil

    self.outColor = {0, 0, 0}
    self.outWidth = 0
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

function Text:destroy()
    self.exists = false
    self.content = nil
    self.outWidth = 0
end

function Text:draw()
    if self.exists then
        local font = love.graphics.getFont()
        local r, g, b, a = love.graphics.getColor()
        local min, mag, anisotropy = self.font:getFilter()
        local shader = love.graphics.getShader()

        local mode = self.antialiasing and "linear" or "nearest"
        self.font:setFilter(mode, mode)
        if self.shader then love.graphics.setShader(self.shader) end
        love.graphics.setBlendMode(self.blend)

        local cameras = self.cameras or Camera.__defaultCameras
        for _, cam in ipairs(cameras) do
            local alpha = self.alpha * cam.alpha
            if self.visible and alpha > 0 then
                cam:attach()

                love.graphics.setFont(self.font)
                love.graphics.setColor(self.outColor[1], self.outColor[2],
                                       self.outColor[3], alpha)

                if self.outWidth > 0 then
                    for dx = -self.outWidth, self.outWidth do
                        for dy = -self.outWidth, self.outWidth do
                            love.graphics.printf(self.content, self.x + dx, self.y + dy,
                                                 (self.limit or self:getWidth()),
                                                 self.alignment)
                        end
                    end
                end

                love.graphics.setColor(self.color[1], self.color [2], self.color[3], alpha)
                love.graphics.printf(self.content, self.x, self.y,
                                     (self.limit or self:getWidth()), self.alignment)

                love.graphics.setFont(font)
                love.graphics.setColor(r, g, b, a)
                cam:detach()
            end
        end

        self.font:setFilter(min, mag, anisotropy)
        love.graphics.setBlendMode("alpha")
        if self.shader then love.graphics.setShader(shader) end
    end
end

return Text
