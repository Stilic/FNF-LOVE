function create()
	self:setFrames(paths.getSparrowAtlas("characters/BOYFRIEND"))

	self:addAnimByPrefix("idle", "BF idle dance", 24, false)
	self:addAnimByPrefix("singUP", "BF NOTE UP0", 24, false)
	self:addAnimByPrefix("singLEFT", "BF NOTE LEFT0", 24, false)
	self:addAnimByPrefix("singRIGHT", "BF NOTE RIGHT0", 24, false)
	self:addAnimByPrefix("singDOWN", "BF NOTE DOWN0", 24, false)
	self:addAnimByPrefix("singUPmiss", "BF NOTE UP MISS0", 24, false)
	self:addAnimByPrefix("singLEFTmiss", "BF NOTE LEFT MISS0", 24, false)
	self:addAnimByPrefix("singRIGHTmiss", "BF NOTE RIGHT MISS0", 24, false)
	self:addAnimByPrefix("singDOWNmiss", "BF NOTE DOWN MISS0", 24, false)

	self:addOffset("idle", -5, 0)
	self:addOffset("singUP", -46, 28)
	self:addOffset("singRIGHT", -49, -6)
	self:addOffset("singLEFT", 3, -7)
	self:addOffset("singDOWN", -20, -51)
	self:addOffset("singUPmiss", -43, 26)
	self:addOffset("singRIGHTmiss", -44, 22)
	self:addOffset("singLEFTmiss", 1, 20)
	self:addOffset("singDOWNmiss", -20, -21)

	self.flipX = true
	self.y = self.y + 350
	self.icon = "bf"

	close()
end
