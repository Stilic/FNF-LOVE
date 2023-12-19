---@class Button:Graphic
local Button = Graphic:extend("Button")

function Button:new(x, y, width, height, key, color)
    Button.super.new(self, x, y)
    self.width = width
    self.height = height
    self.key = key
    self.color = color or {1, 1, 1}

    self.scrollFactor = {x = 0, y = 0}

    self.pressed = false
    self.pressedAlpha = 1
    self.releasedAlpha = 0.25
end

function Button:update(dt)
    if not self.pressed then
        self.alpha = util.coolLerp(self.alpha, self.releasedAlpha, 0.24)
    else
        self.alpha = self.pressedAlpha
    end
end

return Button