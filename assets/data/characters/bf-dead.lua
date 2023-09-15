function create()
    self:setFrames(paths.getSparrowAtlas('characters/BOYFRIEND_DEAD'))

    self:addAnimByPrefix('firstDeath', 'BF dies', 24, false)
    self:addAnimByPrefix('deathLoop', 'BF Dead Loop', 24, true)
    self:addAnimByPrefix('deathConfirm', 'BF Dead confirm', 24, false)

    self:addOffset('firstDeath', 37, 11)
    self:addOffset('deathLoop', 37, 5)
    self:addOffset('deathConfirm', 37, 69)

    self.flipX = true
    self.icon = 'bf'
    self.y = self.y + 350

    close()
end
