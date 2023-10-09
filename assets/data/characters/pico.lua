-- Converted By Fellynn
function create()
	self:setFrames(paths.getSparrowAtlas('characters/Pico_FNF_assetss'))

	self:addAnimByPrefix('idle', 'Pico Idle Dance', 24, false)
	self:addAnimByPrefix('singUP', 'pico Up note0', 24, false)
	self:addAnimByPrefix('singDOWN', 'Pico Down Note0', 24, false)
	self:addAnimByPrefix('singDOWNmiss', 'Pico Down Note MISS', 24, false)
	self:addAnimByPrefix('singUPmiss', 'pico Up note miss', 24, false)
	self:addAnimByPrefix('singRIGHT', 'Pico Note Right0', 24, false)
	self:addAnimByPrefix('singLEFT', 'Pico NOTE LEFT0', 24, false)
	self:addAnimByPrefix('singRIGHTmiss', 'Pico Note Right Miss', 24, false)
	self:addAnimByPrefix('singLEFTmiss', 'Pico NOTE LEFT miss', 24, false)

	self:addOffset('idle', 3, 0)
	self:addOffset('singUP', 21, 27)
	self:addOffset('singDOWN', 84, -80)
	self:addOffset('singDOWNmiss', 80, -38)
	self:addOffset('singUPmiss', 28, 67)
	self:addOffset('singRIGHT', -48, 2)
	self:addOffset('singLEFT', 85, -10)
	self:addOffset('singRIGHTmiss', -45, 50)
	self:addOffset('singLEFTmiss', 83, 28)

	self.x = self.x + -300
	self.y = self.y + 300
	self.cameraPosition = {x = 300, y = 50}
	self.icon = "pico"
	self.flipX = true
end