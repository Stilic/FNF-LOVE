local CutsceneState = State:extend("CutsceneState")

function CutsceneState:enter()
    love.mouse.setVisible(true)

    self.camHUD = Camera()
	self.camOther = Camera()
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camOther, false)

    self.data = {
        player1 = 'bf',
        player2 = 'dad',
        gfVersion = 'gf',
        stage = 'stage'
    }

    self.stage = Stage(self.data.stage)
	self:add(self.stage)

    self.camFollow = {x = game.width / 2, y = game.height / 2}
    game.camera.target = {x = self.camFollow.x, y = self.camFollow.y}
    game.camera.zoom = self.stage.camZoom

    self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
		self.data.gfVersion, false)
	self.gf:setScrollFactor(0.95, 0.95)

	self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y,
		self.data.player2, false)

	self.boyfriend = Character(self.stage.boyfriendPos.x,
		self.stage.boyfriendPos.y, self.data.player1, true)

	self:add(self.gf)
	self:add(self.dad)
	self:add(self.boyfriend)

    self:add(self.stage.foreground)

    self.navbar = ui.UINavbar({
		{"File", function() end},
		{"Edit", function() end},
		{"Cutscene", function() end}
	})
	self.navbar.cameras = {self.camHUD}
	self:add(self.navbar)
end

function CutsceneState:update(dt)
    CutsceneState.super.update(self, dt)

    local shiftMult = game.keys.pressed.SHIFT and 10 or 1

    if game.keys.pressed.A then
        self.camFollow.x = self.camFollow.x - (2 + shiftMult)
    elseif game.keys.pressed.D then
        self.camFollow.x = self.camFollow.x + (2 + shiftMult)
    end
    if game.keys.pressed.W then
        self.camFollow.y = self.camFollow.y - (2 + shiftMult)
    elseif game.keys.pressed.S then
        self.camFollow.y = self.camFollow.y + (2 + shiftMult)
    end

    if game.keys.justPressed.ESCAPE then
        game.sound.playMusic(paths.getMusic("freakyMenu"))
        game.switchState(MainMenuState())
    end

	game.camera.target.x, game.camera.target.y =
		util.coolLerp(game.camera.target.x, self.camFollow.x, 12, dt),
		util.coolLerp(game.camera.target.y, self.camFollow.y, 12, dt)
end

function CutsceneState:leave()
    love.mouse.setVisible(false)
end

return CutsceneState