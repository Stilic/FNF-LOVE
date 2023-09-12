function create()
    self:setFrames(paths.getSparrowAtlas('characters/senpai'))

    self:makeCharacterAnim('idle', 'Senpai Idle', nil, 24, false, {1, 0})
    self:makeCharacterAnim('singUP', 'SENPAI UP NOTE', nil, 24, false, {5, 37})
    self:makeCharacterAnim('singRIGHT', 'SENPAI RIGHT NOTE', nil, 24, false, {0, 0})
    self:makeCharacterAnim('singLEFT', 'SENPAI LEFT NOTE', nil, 24, false, {40, 0})
    self:makeCharacterAnim('singDOWN', 'SENPAI DOWN NOTE', nil, 24, false, {14, 0})

    self.antialiasing = false
    self.x, self.y = self.x + 150, self.y + 360
    self.icon = 'senpai'
    self.flipX = false
    self.cameraPosition = {
        x = -240,
        y = -330
    }
    self.scaleChar = 6

    close()
end