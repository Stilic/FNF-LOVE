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

	self.updateCam = false
	self.isFollowing = false

	self.playingDeathSound = false
	self.startedDeath = false
	self.isEnding = false

	self.boyfriend = Character(x, y, GameOverSubstate.characterName, true)
	self:add(self.boyfriend)

	local boyfriendMidpointX, boyfriendMidpointY = self.boyfriend:getGraphicMidpoint()
	self.camFollow = {x = boyfriendMidpointX, y = boyfriendMidpointY}

	if love.system.getDevice() == "Mobile" then
		self.buttons = ButtonGroup()
		local w = 134

		local enter = Button("return", game.width - w, down.y)
		enter.color = Color.GREEN
		local back = Button("escape", enter.x - w, down.y)
		back.color = Color.RED

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end
end

function GameOverSubstate:enter(x, y)
	PlayState.notePosition = 0

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
					function() game.resetState() end)
			end)
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
				self.updateCam = true
				self.isFollowing = true
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

	if self.updateCam then
		game.camera.target.x, game.camera.target.y =
			util.coolLerp(game.camera.target.x, self.camFollow.x, 2.4, dt),
			util.coolLerp(game.camera.target.y, self.camFollow.y, 2.4, dt)
	end
end

return GameOverSubstate
