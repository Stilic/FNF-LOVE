function create()
    self:setFrames(paths.getSparrowAtlas('characters/gfPixel'))

    self:makeCharacterAnim('danceLeft', 'GF IDLE', {30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, 24, false, {0, 0})
    self:makeCharacterAnim('danceRight', 'GF IDLE', {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29}, 24, false, {0, 0})
    self:makeCharacterAnim('singUP', 'GF IDLE', nil, 24, false, {0 ,0})

    self.antialiasing = false
    self.icon = "gf"
    self.flipX = false
    self.cameraPosition = {
        x = -20,
		y = 80
    }
    self.scaleChar = 6

    self.danceSpeed = 1

    close()
end