function create()
	self:setFrames(paths.getSparrowAtlas('characters/BOYFRIEND'))

	self:addAnimByPrefix('idle', 'BF idle dance', 24, false)
	self:addAnimByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false)
	self:addAnimByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false)
	self:addAnimByPrefix('singUP', 'BF NOTE UP0', 24, false)
	self:addAnimByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false)
	self:addAnimByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false)
	self:addAnimByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false)
	self:addAnimByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false)
	self:addAnimByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false)
	self:addAnimByPrefix('hey', 'BF HEY', 24, false)
	self:addAnimByPrefix('hurt', 'BF hit', 24, false)
	self:addAnimByPrefix('scared', 'BF idle shaking', 24, true)
	self:addAnimByPrefix('dodge', 'boyfriend dodge', 24, false)
	self:addAnimByPrefix('attack', 'boyfriend attack', 24, false)
	self:addAnimByPrefix('pre-attack', 'bf pre attack', 24, false)

	self:addOffset('idle', -5, 0)
	self:addOffset('singLEFT', 5, -6)
	self:addOffset('singDOWN', -20, -51)
	self:addOffset('singUP', -46, 27)
	self:addOffset('singRIGHT', -48, -7)
	self:addOffset('singLEFTmiss', 7, 19)
	self:addOffset('singDOWNmiss', -15, -19)
	self:addOffset('singUPmiss', -46, 27)
	self:addOffset('singRIGHTmiss', -44, 22)
	self:addOffset('hey', -3, 5)
	self:addOffset('hurt', 14, 18)
	self:addOffset('scared', -4, 0)
	self:addOffset('dodge', -10, -16)
	self:addOffset('attack', 294, 267)
	self:addOffset('pre-attack', -40, -40)

	self.y = self.y + 350
	self.icon = "bf"
	self.flipX = true

	close()
end