local NoteSplash = Sprite:extend()

function NoteSplash:new(x, y)
    NoteSplash.super.new(self, x, y)

    self:setFrames(paths.getSparrowAtlas("skins/normal/noteSplashes"))
    self.antialiasing = true

    for i = 0, 1, 1 do
        for j = 0, 3, 1 do
            if j == 1 and i == 0 then
                self:addAnimByPrefix('note1-0', 'note impact 1  blue', 24, false)
            else
                self:addAnimByPrefix(
                    'note' .. tostring(j) .. '-' .. tostring(i),
                    'note impact ' .. (i + 1) .. ' ' .. Note.colors[j + 1], 24,
                    false)
            end
        end
    end
end

function NoteSplash:setup(data)
    self.alpha = 0.6

    self:play('note' .. data .. '-' .. tostring(math.random(0, 1)), true)
    self.curAnim.framerate = 24 + math.random(-2, 2)
    self:updateHitbox()

    self.offset.x, self.offset.y = self.width * 0.3, self.height * 0.3
end

function NoteSplash:update(dt)
    if self.alive and self.animFinished then self:kill() end

    NoteSplash.super.update(self, dt)
end

return NoteSplash
