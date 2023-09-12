function create()
	self:setFrames(paths.getSparrowAtlas("characters/GF_assets"))

	self:addAnimByIndices("danceLeft", "GF Dancing Beat", { 30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }, 24, false)
	self:addAnimByIndices("danceRight", "GF Dancing Beat", { 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29 }, 24, false)
	self:addAnimByPrefix("cheer", "GF Cheer", 24, false)
	self:addAnimByPrefix("singLEFT", "GF left note", 24, false)
	self:addAnimByPrefix("singRIGHT", "GF Right Note", 24, false)
	self:addAnimByPrefix("singUP", "GF Up Note", 24, false)
	self:addAnimByPrefix("singDOWN", "GF Down Note", 24, false)
	self:addAnimByIndices("sad", "gf sad", { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, 24, false)
	self:addAnimByIndices("hairBlow", "GF Dancing Beat Hair blowing", { 0, 1, 2, 3 }, 24, false)
	self:addAnimByIndices("hairFall", "GF Dancing Beat Hair Landing", { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }, 24, false)
	self:addAnimByPrefix("scared", "GF FEAR", 24, false)

	self:addOffset("danceLeft", 0, -9)
	self:addOffset("danceRight", 0, -9)
	self:addOffset("cheer", 3, 0)
	self:addOffset("singLEFT", 0, -19)
	self:addOffset("singRIGHT", 0, -20)
	self:addOffset("singUP", 0, 4)
	self:addOffset("singDOWN", 0, -20)
	self:addOffset("sad", -2, -21)
	self:addOffset("hairBlow", 45, -8)
	self:addOffset("hairFall", 0, -9)
	self:addOffset("scared", -2, -17)

	self.danceSpeed = 1

	self.icon = 'gf'

	close()
end
