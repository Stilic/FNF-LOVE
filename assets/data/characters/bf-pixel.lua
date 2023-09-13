function create()
    self:setFrames(paths.getSparrowAtlas('characters/bfPixel'))

    self:makeCharacterAnim('idle', 'BF IDLE', nil, 24, false, {7, 0})
    self:makeCharacterAnim('singLEFT', 'BF LEFT NOTE', nil, 24, false, {0, 0})
    self:makeCharacterAnim('singDOWN', 'BF DOWN NOTE', nil, 24, false, {0, 0})
    self:makeCharacterAnim('singUP', 'BF UP NOTE', nil, 24, false, {0, 0})
    self:makeCharacterAnim('singRIGHT', 'BF RIGHT NOTE', nil, 24, false, {0, 0})
    self:makeCharacterAnim('singLEFTmiss', 'BF LEFT MISS', nil, 24, false,
                           {0, 0})
    self:makeCharacterAnim('singDOWNmiss', 'BF DOWN MISS', nil, 24, false,
                           {0, 0})
    self:makeCharacterAnim('singUPmiss', 'BF UP MISS', nil, 24, false, {0, 0})
    self:makeCharacterAnim('singRIGHTmiss', 'BF RIGHT MISS', nil, 24, false,
                           {0, 0})

    self.antialiasing = false
    self.y = self.y + 350
    self.icon = "bf-pixel"
    self.flipX = true
    self.cameraPosition = {x = 50, y = -60}
    self.scaleChar = 6

    close()
end
