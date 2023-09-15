function create()
    self:setFrames(paths.getSparrowAtlas('characters/bfPixel'))

    self:addAnimByPrefix('idle', 'BF IDLE', 24, false)
    self:addAnimByPrefix('singLEFT', 'BF LEFT NOTE', 24, false)
    self:addAnimByPrefix('singDOWN', 'BF DOWN NOTE', 24, false)
    self:addAnimByPrefix('singUP', 'BF UP NOTE', 24, false)
    self:addAnimByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false)
    self:addAnimByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false)
    self:addAnimByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false)
    self:addAnimByPrefix('singUPmiss', 'BF UP MISS', 24, false)
    self:addAnimByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false)

    self:addOffset('idle', 7, 0)
    self:addOffset('singLEFT', 0, 0)
    self:addOffset('singDOWN', 0, 0)
    self:addOffset('singUP', 0, 0)
    self:addOffset('singRIGHT', 0, 0)
    self:addOffset('singLEFTmiss', 0, 0)
    self:addOffset('singDOWNmiss', 0, 0)
    self:addOffset('singUPmiss', 0, 0)
    self:addOffset('singRIGHTmiss', 0, 0)

    self.antialiasing = false
    self.y = self.y + 350
    self.icon = "bf-pixel"
    self.flipX = true
    self.cameraPosition = {x = 50, y = -60}
    self:setGraphicSize(math.floor(self.width * 6))
    self:updateHitbox()

    close()
end
