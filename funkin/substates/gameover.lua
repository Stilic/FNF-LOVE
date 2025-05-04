local GameOverSubstate = Substate:extend("GameOverSubstate")
GameOverSubstate.deaths = 0

function GameOverSubstate.resetVars()
	GameOverSubstate.characterName = 'bf-dead'
	GameOverSubstate.deathSoundName = 'gameplay/fnf_loss_sfx'
	GameOverSubstate.loopSoundName = 'gameOver'
	GameOverSubstate.endSoundName = 'gameOverEnd'
	GameOverSubstate.loseImageName = 'skins/default/lose'
end

GameOverSubstate.resetVars()

function GameOverSubstate:new(x, y)
	GameOverSubstate.super.new(self)

	self.startedDeath = false
	self.isEnding = false

	self.followTime = 0.5
	self.time = 0

	local w, h = game.camera.width / game.camera.zoom,
		game.camera.height / game.camera.zoom

	self.bg = Graphic(-w / 2, -h / 2, w * 2, h * 2, Color.BLACK)
	self.bg.alpha = 0
	self.bg.scrollFactor:set()
	self:add(self.bg)

	self.boyfriend = Character(x, y, GameOverSubstate.characterName, true)
	self:add(self.boyfriend)

	self.camFollow = Point(self.boyfriend:getGraphicMidpoint())

	if love.system.getDevice() == "Mobile" then
		local camButtons = game.getState().camOther

		self.buttons = util.createButtons("ab")
		self.buttons.cameras = {camButtons}

		self:add(self.buttons)
	end

	-- if ClientPrefs.data.gameOverInfos then
		-- local lose = Sprite(game.width / 2, 23); self.lose = lose
		-- lose:setFrames(paths.getSparrowAtlas(GameOverSubstate.loseImageName))
		-- lose:addAnimByPrefix("lose", "lose", 24, false)

		-- local frame = lose.__animations.lose.frames; frame = frame[#frame]
		-- if frame then
			-- lose.offset.x, lose.offset.y = frame.width / 2, -frame.offset.y
			-- lose.antialiasing = ClientPrefs.data.antialiasing
		-- else
			-- lose:destroy()
			-- lose = nil
		-- end
	-- end
end

function GameOverSubstate:resetState()
	self.lock = true

	self.load = LoadScreen(getmetatable(game.getState())())
	self:add(self.load)
end	

function GameOverSubstate:enter()
	self.scripts = self.parent.scripts or ScriptsHandler()
	self.boyfriend:playAnim('firstDeath')

	game.sound.music.pitch = 1
	paths.getMusic(GameOverSubstate.loopSoundName)
	paths.getMusic(GameOverSubstate.endSoundName)
	util.playSfx(paths.getSound(GameOverSubstate.deathSoundName))

	self.scripts:call("gameOverStart")
end

function GameOverSubstate:update(dt)
	self.scripts:call("gameOverUpdate", dt)
	if self.load then
		if paths.async.getProgress() == 1 then
			local state = self.load.nextState
			state.skipTransIn = true
			self.parent.skipTransOut = true
			game.switchState(state)
		end
	end
	GameOverSubstate.super.update(self, dt)

	if not self.isEnding then
		if controls:pressed('back') then
			self.scripts:call("gameOverQuit")

			util.playMenuMusic()
			GameOverSubstate.deaths = 0
			local state = PlayState.isStoryMode and StoryMenuState or FreeplayState
			local stickers = Stickers()
			self:add(stickers)
			stickers:start(state())
			self.isEnding = true
		end

		if controls:pressed('accept') then
			self.scripts:call("gameOverConfirm")

			self.isEnding = true
			self.boyfriend:playAnim('deathConfirm', true)
			game.sound.music:stop()

			game.sound.play(paths.getMusic(GameOverSubstate.endSoundName), ClientPrefs.data.musicVolume / 100)

			Tween.cancelTweensOf(self.bg)
			Tween.cancelTweensOf(game.camera)

			Timer.wait(0.7, function()
				Tween.tween(game.camera, {alpha = 0}, 2, {onComplete = function()
					self:resetState()
				end})
			end)

			Tween.tween(self.bg, {alpha = 1}, 2, {ease = 'cubeOut'})
			if self.buttons then Tween.tween(self.buttons, {alpha = 0}, 1.5, {ease = 'cubeOut'}) end
			Tween.tween(game.camera, {zoom = 0.9}, 2, {ease = "cubeOut"})
		end
	end

	if self.time < self.followTime then
		self.time = self.time + dt
		if self.time >= self.followTime then
			self.scripts:call("gameOverFollow")

			game.camera:follow(self.camFollow, nil, 2.4)
			Tween.cancelTweensOf(self.bg)
			Tween.cancelTweensOf(game.camera)
			Tween.tween(self.bg, {alpha = 0.7}, 1, {ease = 'cubeOut'})
			Tween.tween(game.camera, {zoom = 1.1}, 1, {ease = "cubeOut"})

			-- local lose, par = self.lose, self.parent
			-- if par and lose then
				-- lose.cameras = {self.parent.camOther}
				-- Timer.wait(1 - self.followTime, function()
					-- if self.parent ~= par then return end
					-- lose:play('lose')
					-- self:add(lose)
				-- end)
			-- end
		end
	end

	local curAnim = self.boyfriend.animation.curAnim
	if curAnim ~= nil and not self.isEnding then
		if curAnim.name == 'firstDeath' and self.boyfriend.animation.finished
			and not self.startedDeath then
			self.scripts:call("gameOverStartLoop")

			self.startedDeath = true
			self.boyfriend:playAnim('deathLoop')
			game.sound.playMusic(paths.getMusic(GameOverSubstate.loopSoundName),
				ClientPrefs.data.musicVolume / 100, true, false)

			self.scripts:call("postGameOverStartLoop")
		end
	end

	self.scripts:call("postGameOverUpdate", dt)
end

return GameOverSubstate
