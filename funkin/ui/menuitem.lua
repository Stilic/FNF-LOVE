---@class MenuItem:Sprite
local MenuItem = Sprite:extend()

function MenuItem:new(x, y, weekName)
    MenuItem.super.new(self, x, y)
    self:loadTexture(paths.getImage('menus/storymenu/weeks/'..weekName))
    self.targetY = 0
    self.flashingInt = 0
end

local isFlashing = false

function MenuItem:startFlashing()
    isFlashing = true
end

function MenuItem:update(dt)
    MenuItem.super.update(self, dt)

    self.y = math.lerp(self.y, (self.targetY * 120) + 480, math.bound(dt * 10.2, 0, 1))

    if isFlashing then
        self.flashingInt = self.flashingInt + 1
    end

    local fakeFramerate = math.round((1 / dt) / 10)
    if self.flashingInt % fakeFramerate >= math.floor(fakeFramerate / 2) then
        color = Color.fromRGB(51, 255, 255)
    else
        color = Color.WHITE
    end
end

return MenuItem