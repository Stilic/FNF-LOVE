local doof, music

function postCreate()
	local dialogue = love.filesystem.read(paths.getPath('songs/thorns/dialogue.txt')):split('\n')
	local red = Graphic(-150, -150, game.width * 2, game.height * 2, Color.convert({255, 27, 49}))
	local white = Graphic(-150, -150, game.width * 2, game.height * 2, Color.WHITE)
	local black = Graphic(-150, -150, game.width * 2, game.height * 2, Color.BLACK)

	local senpaiEvil = Sprite()
	senpaiEvil:setFrames(paths.getSparrowAtlas('stages/school-evil/senpaiCrazy'))
	senpaiEvil:addAnimByPrefix('idle', 'Senpai Pre Explosion', 24, false)
	senpaiEvil:setGraphicSize(math.floor(senpaiEvil.width * 6))
	senpaiEvil:setScrollFactor()
	senpaiEvil:updateHitbox()
	senpaiEvil:screenCenter()
	senpaiEvil.antialiasing = false
	senpaiEvil.x = senpaiEvil.x + 280

	music = game.sound.play(paths.getMusic('gameplay/LunchboxScary'), 0.8, true, true)

	doof = DialogueBox(dialogue, 2)
	doof:setScrollFactor()
	doof.cameras = {state.camNotes}
	doof.finishThing = function()
		state:startCountdown()
		if state.buttons then state:add(state.buttons) end
		doof:destroy()
		close()
	end

	red:setScrollFactor()
	state:add(red)

	white:setScrollFactor()
	white.alpha = 0

	black:setScrollFactor()
	state:add(black)

	for delay = 1, 7 do
		Timer(timer):start(0.3 * delay, function()
			black.alpha = black.alpha - 0.15
			if black.alpha < 0 then
				state:remove(black)
			end
		end)
	end

	state.camHUD.visible, state.camNotes.visible = false, false

	Timer(timer):start(2.1, function()
		state:add(senpaiEvil)
		senpaiEvil.alpha = 0
		state:add(white)
		for delay = 1, 7 do
			Timer(timer):start(0.3 * delay, function()
				senpaiEvil.alpha = senpaiEvil.alpha + 0.15
				if senpaiEvil.alpha > 1 then
					senpaiEvil.alpha = 1

					Tween.tween(game.camera, {zoom = state.stage.camZoom - 0.2}, 2.4, {ease = Ease.sineIn})

					senpaiEvil:play('idle')
					game.sound.play(paths.getSound('gameplay/Senpai_Dies'), 1, false, true, function()
						state:remove(senpaiEvil)
						state:remove(red)
						state:remove(white)
						game.camera.zoom = state.stage.camZoom
						state:add(doof)
						state.camHUD.visible, state.camNotes.visible = true, true
						state.camHUD:flash(Color.WHITE, 4)
					end)
					Timer(timer):start(2.4, function()
						game.camera.zoom = 1.4
						Tween.tween(game.camera, {zoom = state.stage.camZoom - 0.2}, 1, {ease = Ease.circOut})
						game.camera:shake(0.005, 2.5)
					end)
					Timer(timer):start(3.2, function()
						Tween.tween(white, {alpha = 1}, 1.6)
					end)
				end
			end)
		end
	end)
	if state.buttons then state:remove(state.buttons) end
end

function postUpdate(dt)
	if controls:pressed('accept') and doof.isEnding then
		music:stop()
	end
end

function pause() return Event_Cancel end
