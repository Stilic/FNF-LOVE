local GameOverSubstate = SubState:extend()

function GameOverSubstate.resetVars()
    GameOverSubstate.characterName = 'bf-dead'
    GameOverSubstate.deathSoundName = 'gameplay/fnf_loss_sfx'
    GameOverSubstate.loopSoundName = 'gameOver'
    GameOverSubstate.endSoundName = 'gameOverEnd'
end
GameOverSubstate.resetVars()

function GameOverSubstate:new(x, y)
    GameOverSubstate.super.new(self)

    PlayState.notePosition = 0

    self.updateCam = false
    self.isFollowing = false

    self.playingDeathSound = false
    self.startedDeath = false
    self.isEnding = false

    self.boyfriend = Character(x, y, GameOverSubstate.characterName, true)
    self:add(self.boyfriend)

    self.boyfriend:playAnim('firstDeath')

    paths.getMusic(GameOverSubstate.loopSoundName)
    game.sound.play(paths.getSound(GameOverSubstate.deathSoundName))

    local boyfriendMidpointX, boyfriendMidpointY =
        self.boyfriend:getGraphicMidpoint()
    self.camFollow = {x = boyfriendMidpointX, y = boyfriendMidpointY}
end

function GameOverSubstate:update(dt)
    GameOverSubstate.super.update(self, dt)

    if not self.isEnding then
        if controls:pressed('back') then
            game.sound.music:stop()
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

                    local tankmanLines = 'jeffGameover-'..love.math.random(1, 25)
                    game.sound.play(paths.getSound('gameplay/jeffGameover/'..tankmanLines),
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
            util.coolLerp(game.camera.target.x, self.camFollow.x, 0.04),
            util.coolLerp(game.camera.target.y, self.camFollow.y, 0.04)
    end
end

return GameOverSubstate
