function create()
	self:setFrames(paths.getSparrowAtlas('characters/spooky_kids_assets'))

	self:addAnimByPrefix('hey', 'spooky kids YEAH!!', 24, false)
	self:addAnimByPrefix('singLEFT', 'note sing left', 24, false)
	self:addAnimByPrefix('singRIGHT', 'spooky sing right', 24, false)
	self:addAnimByPrefix('singDOWN', 'spooky DOWN note', 24, false)
	self:addAnimByIndices('danceLeft', 'spooky dance idle', {0, 2, 6}, 12, false)
	self:addAnimByIndices('danceRight', 'spooky dance idle', {8, 10, 12, 14}, 12, false)
	self:addAnimByPrefix('singUP', 'spooky UP NOTE', 24, false)

	self:addOffset('hey', 59, -20)
	self:addOffset('singLEFT', 130, -10)
	self:addOffset('singRIGHT', -130, -14)
	self:addOffset('singDOWN', -50, -130)
	self:addOffset('danceLeft', 0, 0)
	self:addOffset('danceRight', 0, 0)
	self:addOffset('singUP', -20, 26)

	self.y = self.y + 200
	self.icon = "spooky"

	self.danceSpeed = 1

	close()
end