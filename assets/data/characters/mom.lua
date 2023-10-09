-- Converted By Fellynn
function create()
	self:setFrames(paths.getSparrowAtlas('characters/Mom_Assets'))

	self:addAnimByPrefix('idle', 'Mom Idle', 24, false)
	self:addAnimByPrefix('singLEFT', 'Mom Left Pose', 24, false)
	self:addAnimByPrefix('singRIGHT', 'Mom Pose Left', 24, false)
	self:addAnimByPrefix('singDOWN', 'MOM DOWN POSE', 24, false)
	self:addAnimByPrefix('singUP', 'Mom Up Pose', 24, false)

	self:addOffset('idle', 0, 0)
	self:addOffset('singLEFT', 250, -23)
	self:addOffset('singRIGHT', 10, -60)
	self:addOffset('singDOWN', 20, -160)
	self:addOffset('singUP', 14, 71)

	self.icon = "mom"
end