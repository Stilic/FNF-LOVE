function create()
	self:setFrames(paths.getSparrowFrames("characters/tom"))

	self:addAnimByPrefix("idle", "idle", 24, false)
	self:addAnimByPrefix("singUP", "up", 24, false)
	self:addAnimByPrefix("singRIGHT", "right", 24, false)
	self:addAnimByPrefix("singDOWN", "down", 24, false)
	self:addAnimByPrefix("singLEFT", "left", 24, false)

	self:addOffset("singUP", 42, 121)
	self:addOffset("singRIGHT", -65, 60)
	self:addOffset("singLEFT", 46, -27)
	self:addOffset("singDOWN", 145, -20)

	self.x = self.x + 20
	self.y = self.y + 230
	self.cameraPosition = {x = -50, y = 0}
end
