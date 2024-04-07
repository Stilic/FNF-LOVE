local GameOverSubstate = Substate:extend("GameOverSubstate")

function GameOverSubstate.resetVars()
	GameOverSubstate.characterName = 'bf-dead'
	GameOverSubstate.deathSoundName = 'gameplay/fnf_loss_sfx'
	GameOverSubstate.loopSoundName = 'gameOver'
	GameOverSubstate.endSoundName = 'gameOverEnd'
end

GameOverSubstate.resetVars()

function GameOverSubstate:new(x, y)
	GameOverSubstate.super.new(self)

	Timer.setSpeed(1)

	self.isFollowing = false

	self.playingDeathSound = false
	self.startedDeath = false
	self.isEnding = false

	self.bg = Graphic(-game.width, -game.height, game.width * 3, game.height * 3, {0, 0, 0})
	self.bg.alpha = 0
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.boyfriend = Character(x, y, GameOverSubstate.characterName, true)
	self:add(self.boyfriend)

	local boyfriendMidpointX, boyfriendMidpointY = self.boyfriend:getGraphicMidpoint()
	self.camFollow = {x = boyfriendMidpointX, y = boyfriendMidpointY}

	if love.system.getDevice() == "Mobile" then
		local camButtons = Camera()
		game.cameras.add(camButtons, false)

		self.buttons = VirtualPadGroup()
		local w = 134

		local enter = VirtualPad("return", game.width - w, game.height - w)
		enter.color = Color.GREEN
		local back = VirtualPad("escape", enter.x - w, enter.y)
		back.color = Color.RED

		self.buttons:add(enter)
		self.buttons:add(back)
		self.buttons:set({cameras = {camButtons}})

		self:add(self.buttons)
	end
end

function GameOverSubstate:enter(x, y)
	self.boyfriend:playAnim('firstDeath')

	game.sound.music:setPitch(1)
	paths.getMusic(GameOverSubstate.loopSoundName)
	game.sound.play(paths.getSound(GameOverSubstate.deathSoundName))
end

function GameOverSubstate:update(dt)
	GameOverSubstate.super.update(self, dt)

	if not self.isEnding then
		if controls:pressed('back') then
			game.sound.playMusic(paths.getMusic("freakyMenu"))
			game.switchState(FreeplayState())
		end

		if controls:pressed('accept') then
			self.isEnding = true
			self.boyfriend:playAnim('deathConfirm', true)
			game.sound.music:stop()
			game.sound.play(paths.getMusic(GameOverSubstate.endSoundName))
			Timer.after(0.7, function()
				Timer.tween(2, self.boyfriend, {alpha = 0}, "linear",
					function()
						game.resetState()
						if love.system.getDevice() == "Mobile" then
							self.buttons:destroy()
						end
					end)
			end)
			Timer.tween(2, self.bg, {alpha = 1}, 'out-sine')
			Timer.tween(2, game.camera, {zoom = 0.9}, "out-cubic")
		end
	end

	if self.boyfriend.curAnim ~= nil then
		if self.boyfriend.curAnim.name == 'firstDeath' and
			self.boyfriend.animFinished and self.startedDeath then
			self.boyfriend:playAnim('deathLoop')
		end

		if self.boyfriend.curAnim.name == 'firstDeath' then
			if self.boyfriend.curFrame >= 12 and not self.isFollowing then
				game.camera:follow(self.camFollow, nil, 2.4)
				self.isFollowing = true
				Timer.tween(1, self.bg, {alpha = 0.7}, 'in-out-sine')
				Timer.tween(1, game.camera, {zoom = 1.1}, "in-out-cubic")
			end

			if self.boyfriend.animFinished then
				self.startedDeath = true
				game.sound.playMusic(paths.getMusic(
					GameOverSubstate.loopSoundName))
				if PlayState.SONG.stage == 'tank' then
					self.playingDeathSound = true

					game.sound.music:setVolume(0.2)

					local tankmanLines = 'jeffGameover-' ..
						love.math.random(1, 25)
					game.sound.play(paths.getSound(
							'gameplay/jeffGameover/' .. tankmanLines),
						1, false, true, function()
							if not self.isEnding then
								game.sound.music:setVolume(1)
							end
						end)
				end
			end
		end
	end
end

return GameOverSubstate
