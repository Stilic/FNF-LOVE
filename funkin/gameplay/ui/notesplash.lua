local NoteSplash = Sprite:extend("NoteSplash")

function NoteSplash:new(x, y)
	NoteSplash.super.new(self, x, y)

	if PlayState.pixelStage then
		self:setFrames(paths.getSparrowAtlas("skins/pixel/noteSplashes"))
		self:setGraphicSize(math.floor(self.width * 6))
		self:updateHitbox()
		self.antialiasing = false
	else
		self:setFrames(paths.getSparrowAtlas("skins/normal/noteSplashes"))
	end

	for i = 0, 1, 1 do
		for j = 0, 3, 1 do
			if j == 1 and i == 0 then
				self:addAnimByPrefix('note1-0', 'note impact 1  blue', 24, false)
			else
				self:addAnimByPrefix(
					'note' .. tostring(j) .. '-' .. tostring(i),
					'note impact ' .. (i + 1) .. ' ' .. Note.colors[j + 1], 24,
					false)
			end
		end
	end
end

function NoteSplash:setup(data)
	self.alpha = 0.6

	self:play('note' .. data .. '-' .. tostring(math.random(0, 1)), true)
	self.curAnim.framerate = 24 + math.random(-2, 2)
	self:updateHitbox()

	if PlayState.pixelStage then
		self.offset.x, self.offset.y = self.width * -0.13, self.height * -0.07
	else
		self.offset.x, self.offset.y = self.width * 0.3, self.height * 0.3
	end
end

function NoteSplash:update(dt)
	if self.alive and self.animFinished then self:kill() end

	NoteSplash.super.update(self, dt)
end

return NoteSplash
