local HealthIcon = Sprite:extend()

function HealthIcon:new(icon, flip)
    HealthIcon.super.new(self, 0, 0)

    if paths.getImage("icons/" .. icon) == nil then icon = 'face' end
    self:loadTexture(paths.getImage("icons/" .. icon))

    self.static = true
    self.sprTracker = nil

    if self.width > 150 and self.width ~= self.height then
        self.width = self.width / 2
        self:loadTexture(paths.getImage("icons/" .. icon),
                         true, math.floor(self.width), math.floor(self.height))
        self:addAnim("i", {0, 1}, 0)
        self:play("i")

        self.static = false
    end

    self.flipX = flip or false
    if icon:endsWith("-pixel") then self.antialiasing = false end

    self:setScrollFactor()
    self:updateHitbox()
    self.origin = {x = 150, y = 0}
end

function HealthIcon:update(dt)
    HealthIcon.super.update(self, dt)

    if self.sprTracker ~= nil then
        self:setPosition(self.sprTracker.x + self.sprTracker:getWidth()
                         - self.sprTracker.x + 10, self.sprTracker.y - 30)
    end
end

function HealthIcon:swap(frame) if not self.static then self.curFrame = frame end end

return HealthIcon
