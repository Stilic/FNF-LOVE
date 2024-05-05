local AlphaTestState = State:extend("AlphaTestState")

function AlphaTestState:enter()

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuDesat'))
	self.bg:setScrollFactor()
	self.bg:screenCenter()
	self.bg:setGraphicSize(math.floor(self.bg.width * (game.width / self.bg.width)))
	self.bg:updateHitbox()
	self.bg:screenCenter()
	self:add(self.bg)

	self.bd = BackDrop(0, 0, game.width, game.height, 72, nil, {0, 0, 0, 0}, 26)
	self.bd:setScrollFactor()
	self.bd.alpha = 0.5
	self:add(self.bd)

	self.n = Alphabet(-100, -50, '0123456789', true, false)
	self.l = Alphabet(-100, 10, 'abcdefghijklmnopqrstuvwxyz', true, false)
	self:add(self.n)
	self:add(self.l)

	self.camFollow = {x = game.width / 2, y = game.height / 2}

	game.camera.zoom = 0.7

	-- Update Presence
	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Alphabet Testing Menu"})
	end

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local back = VirtualPad("escape", enter.x - w, left.y, w, w)
		back.color = Color.RED

		self.buttons:add(back)

		self:add(self.buttons)
	end

	self.bg.color = Color.RED
	self.bd.color = Color.saturate(self.bg.color, 0.4)

	AlphaTestState.super.enter(self)
end

return AlphaTestState
