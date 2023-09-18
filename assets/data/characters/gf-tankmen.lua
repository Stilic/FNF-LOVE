-- Converted By FelliX
function create()
	self:setFrames(paths.getSparrowAtlas('characters/gfTankmen'))

	self:addAnimByIndices('danceRight', 'GF Dancing at Gunpoint', {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29}, 24, false)
	self:addAnimByIndices('danceLeft', 'GF Dancing at Gunpoint', {30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, 24, false)
	self:addAnimByIndices('sad', 'GF Crying at Gunpoint', {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}, 24, false)

	self:addOffset('danceRight', 0, -9)
	self:addOffset('danceLeft', 0, -9)
	self:addOffset('sad', 0, -27)

	self.icon = "gf"

	self.danceSpeed = 1

	close()
end