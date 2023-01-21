function create()
    self:setFrames(paths.getSparrowFrames("characters/ralt-gf"))

    self:addAnimByIndices("danceLeft", "ralt idle", {
        30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
    }, 24, false)

    self:addAnimByIndices("danceRight", "ralt idle", {
        13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
    }, 24, false)

    self:addOffset("danceLeft", 0, 0)
    self:addOffset("danceRight", 0, 0)

    self.x = self.x + 106
    self.y = self.y + 228
    self.danceSpeed = 1
end
