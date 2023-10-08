local Text = Basic:extend()

function Text:new(x, y, content, font, color, align, limit)
    Text.super.new(self)

    self.x = x or 0
    self.y = y or 0

    self.content = content
    self.font = font or love.graphics.getFont()
    self.alignment = align or "left"
    self.limit = limit

    self.color = color or {1, 1, 1}
    self.alpha = 1
    self.scrollFactor = {x = 1, y = 1}

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
        self.x = (game.width - self.font:getWidth(self.content)) * 0.5
    end
    if axes:find("y") then
        self.y = (game.height - self.font:getHeight(self.content)) * 0.5
    end
end

function Text:setScrollFactor(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    self.scrollFactor.x, self.scrollFactor.y = x, y
end

function Text:destroy()
    Text.super.destroy(self)

    self.content = nil
    self.outWidth = 0
end

function Text:__render(camera)
    local font = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()
    local min, mag, anisotropy = self.font:getFilter()
    local shader = love.graphics.getShader()
    local x, y = self.x - (camera.scroll.x * self.scrollFactor.x),
                 self.y - (camera.scroll.y * self.scrollFactor.y)

    local mode = self.antialiasing and "linear" or "nearest"
    self.font:setFilter(mode, mode)
    if self.shader then love.graphics.setShader(self.shader) end

    local blendMode, alphaMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode(self.blend)

    love.graphics.setFont(self.font)
    love.graphics.setColor(self.outColor[1], self.outColor[2], self.outColor[3],
                           alpha)

    if self.outWidth > 0 then
        for dx = -self.outWidth, self.outWidth do
            for dy = -self.outWidth, self.outWidth do
                love.graphics.printf(self.content, x + dx, y + dy,
                                     (self.limit or self:getWidth()),
                                     self.alignment)
            end
        end
    end

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.printf(self.content, x, y, (self.limit or self:getWidth()),
                         self.alignment)

    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, a)

    self.font:setFilter(min, mag, anisotropy)
    love.graphics.setBlendMode("alpha")
    if self.shader then love.graphics.setShader(shader) end
    love.graphics.setBlendMode(blendMode, alphaMode)
end

return Text
