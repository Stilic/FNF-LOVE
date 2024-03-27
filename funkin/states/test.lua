local TestState = State:extend("TestState")

local white, red = {1, 1, 1}, {1, .1, .1}

function TestState:enter()
	self.a = Graphic(0, 0, 130, 100)
	self.a.scale = {x = 2, y = 2}
	self.a:screenCenter()
	self.a:updateHitbox()
	self.a.x = self.a.x - 70

	self.b = Graphic(0, 0, 130, 100)
	self.b:screenCenter()
	self.b:updateHitbox()
	self.b.x = self.b.x + 70
	self.b.origin.x = 0
	self.b.origin.y = 0

	self:add(self.a)
	self:add(self.b)

	TestState.super.enter(self)
	game.sound.playMusic(paths.getMusic("chart_loop"), ClientPrefs.data.musicVolume)
end

function TestState:update(dt)
	local pix = game.keys.pressed.SHIFT and 300 or 150

	if game.keys.pressed.A then self.a.x = self.a.x - dt * pix end
	if game.keys.pressed.D then self.a.x = self.a.x + dt * pix end
	if game.keys.pressed.W then self.a.y = self.a.y - dt * pix end
	if game.keys.pressed.S then self.a.y = self.a.y + dt * pix end
	if game.keys.pressed.Q then self.a.angle = self.a.angle - dt * (pix / 3) end
	if game.keys.pressed.E then self.a.angle = self.a.angle + dt * (pix / 3) end

	if game.keys.pressed.R then game.camera.zoom = game.camera.zoom - (pix / 1600) end
	if game.keys.pressed.F then game.camera.zoom = game.camera.zoom + (pix / 1600) end

	if game.keys.pressed.LEFT then self.b.x = self.b.x - dt * pix end
	if game.keys.pressed.RIGHT then self.b.x = self.b.x + dt * pix end
	if game.keys.pressed.UP then self.b.y = self.b.y - dt * pix end
	if game.keys.pressed.DOWN then self.b.y = self.b.y + dt * pix end
	if game.keys.pressed.NUMPADONE then self.b.angle = self.b.angle - dt * (pix / 3) end
	if game.keys.pressed.NUMPADTHREE then self.b.angle = self.b.angle + dt * (pix / 3) end

	local x1, y1, w1, h1, sx1, sy1, ox1, oy1 = self.a:_getBoundary()
	local x2, y2, w2, h2, sx2, sy2, ox2, oy2 = self.b:_getBoundary()
	if Object.checkCollisionFast(x1, y1, w1, h1, sx1, sy1, ox1, oy1, self.a.angle, x2, y2, w2, h2, sx2, sy2, ox2, oy2, self.b.angle) then
		self.a.color = red
		self.b.color = red
	else
		self.a.color = white
		self.b.color = white
	end

	TestState.super.update(self, dt)
end

function TestState:meh()
	self.optionsUI = self.optionsUI or Options(true, function()
		self:meh()
	end)
	self.optionsUI:setScrollFactor()
	self.optionsUI:screenCenter()
	self:add(self.optionsUI)
end

function TestState:leave()
	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil
end

return TestState
