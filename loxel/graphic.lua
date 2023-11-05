local Graphic = Basic:extend()

function Graphic:new(x, y, width, height, color, type, fill)
    Graphic.super.new(self)

    self.x = x or 0
    self.y = y or 0

    self.type = type or "rectangle"
    self.fill = fill or "fill"

    self.config = {
        arctype = "open",
        radius = 100,
        angle1 = 0,
        angle2 = 180,
        segments = 20,
        vertices = nil
    }

    self.width = width or 0
    self.height = height or 0

    self.outWidth = 6

    self.antialiasing = false

    self.scrollFactor = {x = 1, y = 1}

    self.color = color or {0, 0, 0}
    self.alpha = 1
    self.angle = 0

    self.shader = nil
    self.blend = "alpha"
end

function Graphic:setSize(width, height)
    self.width = width or 0
    self.height = height or 0

    if self.type ~= ("rectangle" or "polygon") then
        self.config.radius = self.width
    end
    if self.type == "polygon" then self.outWidth = self.width end
end

function Graphic:setScrollFactor(x, y)
    self.scrollFactor.x = x or 0
    self.scrollFactor.y = y or 0
end

function Graphic:getMidpoint()
    return self.x + self.width * 0.5, self.y + self.height * 0.5
end

function Graphic:setPosition(x, y)
    self.x = x or 0
    self.y = y or 0
end

function Graphic:updateDimensions()
    if self.type ~= ("rectangle" or "polygon") then
        self.width = 2 * self.config.radius
        self.height = 2 * self.config.radius
    end
end

function Graphic:screenCenter(axes)
    if axes == nil then axes = "xy" end
    if axes:find("x") then self.x = (game.width - self.width) * 0.5 end
    if axes:find("y") then self.y = (game.height - self.height) * 0.5 end
    return self
end

function Graphic:draw()
    if self.width > 0 or self.height > 0 or self.config.radius > 0 or
        self.points then Graphic.super.draw(self) end
end

function Graphic:__render(camera)
    local shader = love.graphics.getShader()
    local lineWidth = love.graphics.getLineWidth()
    local lineStyle = love.graphics.getLineStyle()

    if self.shader then love.graphics.setShader(self.shader) end
    love.graphics.setBlendMode(self.blend)

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)

    local angle = math.rad(self.angle)
    local w, h = self.width, self.height

    local ang1, ang2 = self.config.angle1 * (math.pi / 180),
                       self.config.angle2 * (math.pi / 180)

    x, y = self.x - (camera.scroll.x * self.scrollFactor.x),
           self.y - (camera.scroll.y * self.scrollFactor.y)

    local rad, seg, type = self.config.radius, self.config.segments,
                           self.config.arctype

    love.graphics.setLineWidth(self.outWidth)

    local antialiasing = (self.antialiasing and "rough" or "smooth")
    love.graphics.setLineStyle(antialiasing)

    love.graphics.push()
    love.graphics.rotate(angle)
    if self.type == "rectangle" then
        love.graphics.rectangle(self.fill, x, y, w, h)

    elseif self.type == "polygon" then
        if self.config.vertices then
            love.graphics.translate(x, y)
            love.graphics.polygon(self.fill, unpack(self.config.vertices))
        end

    elseif self.type == "circle" then
        love.graphics.circle(self.fill, x, y, rad, seg)

    elseif self.type == "arc" then
        love.graphics.arc(self.fill, type, x, y, rad, ang1, ang2, seg)
    end
    love.graphics.pop()

    love.graphics.setColor(r, g, b, a)

    if self.shader then love.graphics.setShader(shader) end
    love.graphics.setBlendMode("alpha")
    love.graphics.setLineWidth(lineWidth)
    love.graphics.setLineStyle(lineStyle)
end

return Graphic
