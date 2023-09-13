function create()
    self:setFrames(paths.getSparrowAtlas("characters/DADDY_DEAREST"))

    self:addAnimByPrefix("idle", "Dad idle dance", 24, false)
    self:addAnimByPrefix("singUP", "Dad Sing Note UP", 24, false)
    self:addAnimByPrefix("singRIGHT", "Dad Sing Note RIGHT", 24, false)
    self:addAnimByPrefix("singDOWN", "Dad Sing Note DOWN", 24, false)
    self:addAnimByPrefix("singLEFT", "Dad Sing Note LEFT", 24, false)

    self:addOffset("singUP", -6, 50)
    self:addOffset("singRIGHT", 0, 27)
    self:addOffset("singLEFT", -10, 10)
    self:addOffset("singDOWN", 0, -30)

    self.singDuration = 6.1
    self.icon = "dad"

    close()
end
