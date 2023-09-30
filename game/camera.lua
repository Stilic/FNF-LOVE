local Camera = Object:extend()
local cvTable = {nil, stencil = true}

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
    self.exists = true
    self.bgColor = {0, 0, 0, 0}
    self.shader = nil

    self.__canvas = love.graphics.newCanvas()
    self.__renderQueue = {}
end

function Camera:update()
    if self.target then
        self.scroll.x, self.scroll.y = self.target.x - self.width * 0.5,
                                       self.target.y - self.height * 0.5
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

function Camera:draw()
    if self.visible and self.exists and self.alpha > 0 then
        love.graphics.push()
        love.graphics.rotate(-self.angle)
        local w, h = self.width * 0.5, self.height * 0.5
        love.graphics.translate(w - self.x, h - self.y)
        love.graphics.scale(self.zoom, self.zoom)
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

        love.graphics.draw(self.__canvas)

        love.graphics.setShader(shader)
        love.graphics.setColor(r, g, b, a)
        love.graphics.setBlendMode(blendMode, alphaMode)
    end
end

function Camera:destroy()
    self.exists = false

    self.__canvas:release()
    self.__canvas = nil
end

return Camera
