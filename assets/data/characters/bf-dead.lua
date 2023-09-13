function create()
    self:setFrames(paths.getSparrowAtlas('characters/BOYFRIEND_DEAD'))

    self:makeCharacterAnim('firstDeath', 'BF dies', nil, 24, false, {37, 11})
    self:makeCharacterAnim('deathLoop', 'BF Dead Loop', nil, 24, true, {37, 5})
    self:makeCharacterAnim('deathConfirm', 'BF Dead confirm', nil, 24, false,
                           {37, 69})

    self.flipX = true
    self.icon = 'bf'
    self.y = self.y + 350

    close()
end
