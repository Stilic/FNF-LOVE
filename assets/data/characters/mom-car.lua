-- Converted By Fellynn
function create()
	self:setFrames(paths.getSparrowAtlas('characters/momCar'))

	self:addAnimByPrefix('idle', 'Mom Idle', 24, false)
	self:addAnimByPrefix('singLEFT', 'Mom Left Pose', 24, false)
	self:addAnimByPrefix('singRIGHT', 'Mom Pose Left', 24, false)
	self:addAnimByPrefix('singDOWN', 'MOM DOWN POSE', 24, false)
	self:addAnimByPrefix('singUP', 'Mom Up Pose', 24, false)
	self:addAnimByIndices('idle-loop', 'Mom Idle', {10, 11, 12, 13}, 24, true)
	self:addAnimByIndices('singLEFT-loop', 'Mom Left Pose', {6, 7, 8, 9}, 24, true)
	self:addAnimByIndices('singUP-loop', 'Mom Up Pose', {11, 12, 13, 14}, 24, true)
	self:addAnimByIndices('singRIGHT-loop', 'Mom Pose Left', {6, 7, 8, 9}, 24, true)
	self:addAnimByIndices('singDOWN-loop', 'MOM DOWN POSE', {11, 12, 13, 14}, 24, true)

	self:addOffset('idle', 0, 0)
	self:addOffset('singLEFT', 250, -23)
	self:addOffset('singRIGHT', 10, -60)
	self:addOffset('singDOWN', 20, -160)
	self:addOffset('singUP', 14, 71)
	self:addOffset('idle-loop', 0, 0)
	self:addOffset('singLEFT-loop', 250, -23)
	self:addOffset('singUP-loop', 14, 71)
	self:addOffset('singRIGHT-loop', 10, -60)
	self:addOffset('singDOWN-loop', 20, -160)

	self.icon = "mom"
end