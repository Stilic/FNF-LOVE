function create()
    self:setFrames(paths.getSparrowAtlas('characters/senpai'))

    self:addAnimByPrefix('idle', 'Senpai Idle', 24, false)
    self:addAnimByPrefix('singUP', 'SENPAI UP NOTE', 24, false)
    self:addAnimByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false)
    self:addAnimByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false)
    self:addAnimByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false)

    self:addOffset('idle', 1, 0)
    self:addOffset('singUP', 5, 37)
    self:addOffset('singRIGHT', 0, 0)
    self:addOffset('singLEFT', 40, 0)
    self:addOffset('singDOWN', 14, 0)

    self.antialiasing = false
    self.x, self.y = self.x + 150, self.y + 360
    self.icon = 'senpai-pixel'
    self.flipX = false
    self.cameraPosition = {x = -240, y = -330}
    self:setGraphicSize(math.floor(self.width * 6))
    self:updateHitbox()

    close()
end
