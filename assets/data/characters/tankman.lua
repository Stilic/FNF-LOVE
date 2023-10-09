-- Converted By Fellynn
function create()
	self:setFrames(paths.getSparrowAtlas('characters/tankmanCaptain'))

	self:addAnimByPrefix('idle', 'Tankman Idle Dance', 24, false)
	self:addAnimByPrefix('singUP', 'Tankman UP note ', 24, false)
	self:addAnimByPrefix('singDOWN', 'Tankman DOWN note ', 24, false)
	self:addAnimByPrefix('singLEFT', 'Tankman Note Left ', 24, false)
	self:addAnimByPrefix('singRIGHT', 'Tankman Right Note ', 24, false)
	self:addAnimByPrefix('singUP-alt', 'TANKMAN UGH', 24, false)
	self:addAnimByPrefix('singDOWN-alt', 'PRETTY GOOD', 24, false)

	self:addOffset('idle', 0, 0)
	self:addOffset('singUP', 24, 56)
	self:addOffset('singDOWN', 98, -90)
	self:addOffset('singLEFT', 100, -14)
	self:addOffset('singRIGHT', -1, -7)
	self:addOffset('singUP-alt', 24, 56)
	self:addOffset('singDOWN-alt', 98, -90)

	self.y = self.y + 240
	self.icon = 'tankman'
	self.flipX = true

	close()
end