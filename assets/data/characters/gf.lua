function create()
	self:setFrames(paths.getSparrowFrames("characters/GF_assets"))

	self:addAnimByIndices("danceLeft", "GF Dancing Beat", {
		30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
	}, 24, false)
	self:addAnimByIndices("danceRight", "GF Dancing Beat", {
		15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
	}, 24, false)

	self:addOffset("danceLeft", 0, -9)
	self:addOffset("danceRight", 0, -9)

	self.danceSpeed = 1

	close()
end
