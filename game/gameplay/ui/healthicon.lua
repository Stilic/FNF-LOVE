local HealthIcon = Sprite:extend()

function HealthIcon:new(icon, flip)
    HealthIcon.super.new(self, 0, 0)

    self.icon = icon or "face"
    self:load(paths.getImage("icons/icon-" .. self.icon))

    local f0 = Sprite.newFrame("0", 0, 0, 150, self.height,
                               (self.width == 300 and 300 or 150), self.height,
                               75, -75)

    local f1 = Sprite.newFrame("1", 150, 0, 150, self.height, 300, self.height,
                               75, -75)

    if self.width < 300 then f1 = f0 end
    -- not sure that's the way to do it but it's working for now - Vi

    if flip then self.flipX = true end

    self.frames = {f0, f1}
end

function HealthIcon:swap(frame)
    self.curFrameIdx = frame
    self:setFrames({
        texture = paths.getImage("icons/icon-" .. self.icon),
        frames = {self.frames[self.curFrameIdx]}
    })
end

return HealthIcon
