function create()
    self:setFrames(paths.getSparrowAtlas('characters/senpai'))

    self:makeCharacterAnim('idle', 'Angry Senpai Idle', nil, 24, false, {2, 0})
    self:makeCharacterAnim('singUP', 'Angry Senpai UP NOTE', nil, 24, false,
                           {5, 37})
    self:makeCharacterAnim('singRIGHT', 'Angry Senpai RIGHT NOTE', nil, 24,
                           false, {0, 0})
    self:makeCharacterAnim('singLEFT', 'Angry Senpai LEFT NOTE', nil, 24, false,
                           {40, 0})
    self:makeCharacterAnim('singDOWN', 'Angry Senpai DOWN NOTE', nil, 24, false,
                           {14, 0})

    self.antialiasing = false
    self.x, self.y = self.x + 150, self.y + 360
    self.icon = 'senpai'
    self.flipX = false
    self.cameraPosition = {x = -240, y = -330}
    self.scaleChar = 6

    close()
end
