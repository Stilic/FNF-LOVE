local Camera = Basic:extend()
local cvTable = {nil, stencil = true}

Camera.__defaultCameras = {}

function Camera.remapToGame(x, y)
    local scale = {}
    local offset = {}

    local dw, dh
    local ww, wh = love.graphics.getDimensions()
    scale.x = ww / game.width
    scale.y = wh / game.height

    local sv = math.min(scale.x, scale.y)
    if sv >= 1 then sv = math.floor(sv) end

    offset.x = math.floor((scale.x - sv) * (game.width / 2))
    offset.y = math.floor((scale.y - sv) * (game.height / 2))

    scale.x, scale.y = sv, sv

    dw = ww - offset.x * 2
    dh = wh - offset.y * 2

    local nx, ny
    x, y = x - offset.x, y - offset.y
    nx, ny = x / dw, y / dh

    x =
        (x >= 0 and x <= game.width * scale.x) and math.floor(nx * game.width) or
            -1
    y =
        (y >= 0 and y <= game.height * scale.y) and math.floor(ny * game.height) or
            -1

    return x, y
end

function Camera:new(x, y, width, height)
    Camera.super.new(self)

    if x == nil then x = 0 end
    if y == nil then y = 0 end
    if width == nil then width = 0 end
    if width <= 0 then width = game.width end
    if height == nil then height = 0 end
    if height <= 0 then height = game.height end
    self.x = x
    self.y = y
    self.scroll = {x = 0, y = 0}
    self.target = nil
    self.width = width
    self.height = height
    self.alpha = 1
    self.angle = 0
    self.zoom = 1
    self.bgColor = {0, 0, 0, 0}
    self.shader = nil

    self.__canvas = love.graphics.newCanvas(self.width, self.height)
    self.__renderQueue = {}

    self.__flashColor = {1, 1, 1}
    self.__flashAlpha = 0
    self.__flashDuration = 0
    self.__flashComplete = nil

    self.__shakeX = 0
    self.__shakeY = 0
    self.__shakeAxes = 'xy'
    self.__shakeIntensity = 0
    self.__shakeDuration = 0
    self.__shakeComplete = nil
end

function Camera:update(dt)
    if self.target then
        self.scroll.x, self.scroll.y = self.target.x - self.width * 0.5,
                                       self.target.y - self.height * 0.5
    end

    if self.__flashAlpha > 0 then
        self.__flashAlpha = self.__flashAlpha - dt / self.__flashDuration
        if self.__flashAlpha <= 0 and self.__flashComplete ~= nil then
            self.__flashComplete()
        end
    end

    self.__shakeX, self.__shakeY = 0, 0
    if self.__shakeDuration > 0 then
        self.__shakeDuration = self.__shakeDuration - dt
        if self.__shakeDuration <= 0 then
            if self.__shakeComplete ~= nil then
                self.__shakeComplete()
            end
        else
            if self.__shakeAxes:find('x') then
                local shakeVal =
                    love.math.random(-1, 1) * self.__shakeIntensity * self.width
                self.__shakeX = self.__shakeX + shakeVal * self.zoom
            end

            if self.__shakeAxes:find('y') then
                local shakeVal =
                    love.math.random(-1, 1) * self.__shakeIntensity *
                        self.height
                self.__shakeY = self.__shakeY + shakeVal * self.zoom
            end
        end
    end
end

function Camera:fill(r, g, b, a)
    table.insert(self.__renderQueue, function()
        local oR, oG, oB, oA = love.graphics.getColor()

        love.graphics.setColor(r, g, b, a)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)

        love.graphics.setColor(oR, oG, oB, oA)
    end)
end

function Camera:shake(intensity, duration, onComplete, force, axes)
    if not force and (self.__shakeDuration > 0) then return end

    self.__shakeAxes = axes or 'xy'
    self.__shakeIntensity = intensity
    self.__shakeDuration = duration or 1
    self.__shakeComplete = onComplete or nil
end

function Camera:flash(color, duration, onComplete, force)
    if not force and (self.__flashAlpha > 0) then return end

    self.__flashColor = color or {1, 1, 1}
    if duration == nil then duration = 1 end
    if duration <= 0 then duration = 0.000001 end
    self.__flashDuration = duration
    self.__flashComplete = onComplete or nil
    self.__flashAlpha = 1
end

function Camera:draw()
    if self.visible and self.exists and self.alpha ~= 0 and self.zoom ~= 0 then
        love.graphics.push()
        local w, h = self.width * 0.5, self.height * 0.5
        love.graphics.translate(w - self.x + self.__shakeX,
                                h - self.y + self.__shakeY)
        love.graphics.rotate(math.rad(-self.angle))
        love.graphics.scale(self.zoom)
        love.graphics.translate(-w, -h)

        local canvas = love.graphics.getCanvas()
        cvTable[1] = self.__canvas
        love.graphics.setCanvas(cvTable)
        love.graphics.clear(self.bgColor[1], self.bgColor[2], self.bgColor[3],
                            self.bgColor[4])

        for i, o in ipairs(self.__renderQueue) do
            if type(o) == "function" then
                o(self)
            else
                o:__render(self)
            end
            self.__renderQueue[i] = nil
        end

        love.graphics.pop()
        love.graphics.setCanvas(canvas)

        local shader = love.graphics.getShader()
        love.graphics.setShader(self.shader)

        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(1, 1, 1, self.alpha)

        local blendMode, alphaMode = love.graphics.getBlendMode()
        love.graphics.setBlendMode("alpha", "premultiplied")

        local winWidth, winHeight = love.graphics.getDimensions()
        local scale = math.min(winWidth / game.width, winHeight / game.height)
        love.graphics.draw(self.__canvas, (winWidth - scale * game.width) / 2,
                           (winHeight - scale * game.height) / 2, 0, scale,
                           scale)

        love.graphics.setShader(shader)
        love.graphics.setColor(r, g, b, a)
        love.graphics.setBlendMode(blendMode, alphaMode)
    end
end

function Camera:destroy()
    Camera.super.destroy(self)

    self.__canvas:release()
    self.__canvas = nil
end

return Camera
