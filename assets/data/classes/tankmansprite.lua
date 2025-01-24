local TankmanSprite = Sprite:extend("TankmanSprite")

function TankmanSprite:new()
	TankmanSprite.super.new(self)

	self.endingOffset = 0
	self.runSpeed = 0
	self.time = 0
	self.right = false

	self:setFrames(paths.getSparrowAtlas("stages/tank/tankmanKilled1"))
	self:addAnimByPrefix("run", "tankman running", 24, true)
	self:addAnimByPrefix("shot", "John Shot " .. math.random(1, 2), 24, false)

	self:initAnim()

	self:setGraphicSize(math.floor(self.width * 0.4))
	self:updateHitbox()

	self.tankmanFlicker = nil
end

function TankmanSprite:initAnim()
	self:play("run")
	self.curFrame = math.random(1, #self.curAnim.frames)
	self.tankmanFlicker = nil
	self.offset:set(0, 0)
end

function TankmanSprite:revive()
	TankmanSprite.super.revive(self)
	self:initAnim()
end

function TankmanSprite:update(dt)
	TankmanSprite.super.update(self, dt)

	if self.curAnim.name == "shot" and self.curFrame >= 10 and not self.tankmanFlicker then
		self.tankmanFlicker = true
		Timer():start(1, function() self:kill() end)
	end

	if PlayState.conductor.time >= self.time and self.curAnim.name == "run" then
		self:play("shot")
		self.offset:set(self.flipX and -300 or 300, 200)
	end

	if self.curAnim.name == "run" then
		local base = self.right and game.width * 0.74 + self.endingOffset or
			game.width * 0.02 - self.endingOffset
		local cond = (PlayState.conductor.time - self.time) * self.runSpeed
		self.x = base + cond * (self.right and -1 or 1)
	end
end

return TankmanSprite
