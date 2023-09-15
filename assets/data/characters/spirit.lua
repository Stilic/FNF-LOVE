function create()
    self:setFrames(paths.getPackerAtlas('characters/spirit'))

    self:addAnimByPrefix('idle', 'idle spirit_', 24, false)
    self:addAnimByPrefix('singUP', 'up_', 24, false)
    self:addAnimByPrefix('singRIGHT', 'right_', 24, false)
    self:addAnimByPrefix('singLEFT', 'left_', 24, false)
    self:addAnimByPrefix('singDOWN', 'spirit down_', 24, false)

    self:addOffset('idle', -218, -280)
    self:addOffset('singUP', -220, -240)
    self:addOffset('singRIGHT', -220, -280)
    self:addOffset('singLEFT', -200, -280)
    self:addOffset('singDOWN', 170, 110)

    self.antialiasing = false
    self.x, self.y = self.x + -150, self.y + 100
    self.icon = 'spirit-pixel'
    self.flipX = false
    self.cameraPosition = {x = 0, y = 0}
    self:setGraphicSize(math.floor(self.width * 6))
    self:updateHitbox()

    close()
end