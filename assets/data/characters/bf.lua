function create()
	self:setFrames(paths.getSparrowFrames("characters/BOYFRIEND"))

	self:addAnimByPrefix("idle", "BF idle dance", 24, false)
	self:addAnimByPrefix("singUP", "BF NOTE UP0", 24, false)
	self:addAnimByPrefix("singLEFT", "BF NOTE LEFT0", 24, false)
	self:addAnimByPrefix("singRIGHT", "BF NOTE RIGHT0", 24, false)
	self:addAnimByPrefix("singDOWN", "BF NOTE DOWN0", 24, false)

	self:addOffset("idle", -5, 0)
	self:addOffset("singUP", -46, 28)
	self:addOffset("singRIGHT", -49, -6)
	self:addOffset("singLEFT", 3, -7)
	self:addOffset("singDOWN", -20, -51)

	self.flipX = true
	self.y = self.y + 350

	close()
end
