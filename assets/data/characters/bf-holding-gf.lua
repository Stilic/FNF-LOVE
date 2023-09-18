-- Converted By FelliX
function create()
	self:setFrames(paths.getSparrowAtlas('characters/bfAndGF'))

	self:addAnimByPrefix('idle', 'BF idle dance', 24, false)
	self:addAnimByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false)
	self:addAnimByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false)
	self:addAnimByPrefix('singUP', 'BF NOTE UP0', 24, false)
	self:addAnimByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false)
	self:addAnimByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false)
	self:addAnimByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false)
	self:addAnimByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false)
	self:addAnimByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false)
	self:addAnimByPrefix('bfCatch', 'BF catches GF', 24, false)

	self:addOffset('idle', -5, 0)
	self:addOffset('singLEFT', 12, 7)
	self:addOffset('singDOWN', -10, -10)
	self:addOffset('singUP', -29, 10)
	self:addOffset('singRIGHT', -41, 23)
	self:addOffset('singLEFTmiss', 12, 7)
	self:addOffset('singDOWNmiss', -10, -10)
	self:addOffset('singUPmiss', -29, 10)
	self:addOffset('singRIGHTmiss', -41, 33)
	self:addOffset('bfCatch', 0, 90)

	self.y = self.y + 350
	self.icon = "bf"
	self.flipX = true

	close()
end