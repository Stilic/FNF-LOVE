local music

local function makeDialogueBox()
	local doof = DialogueBox("pixel", "thorns", paths.formatToSongPath(PlayState.SONG.song))
	doof.cameras = {camNotes}
	doof.onFinish = function()
		music:stop()
		close()
	end
	add(doof)
end

function postCreate()
	local red = Graphic(-150, -150, game.width * 2, game.height * 2, Color.convert({255, 27, 49}))
	local white = Graphic(-150, -150, game.width * 2, game.height * 2, Color.WHITE)
	local black = Graphic(-150, -150, game.width * 2, game.height * 2, Color.BLACK)

	local senpaiEvil = Sprite(27, -22)
	senpaiEvil:setFrames(paths.getSparrowAtlas('stages/school-evil/senpaiCrazy'))
	senpaiEvil:addAnimByPrefix('idle', 'Senpai Pre Explosion', 24, false)
	senpaiEvil:setScrollFactor()
	senpaiEvil:updateHitbox()
	senpaiEvil.antialiasing = false

	music = game.sound.play(paths.getMusic('gameplay/LunchboxScary'), 0.8, true, true)

	red:setScrollFactor()
	add(red)

	white:setScrollFactor()
	white.alpha = 0

	black:setScrollFactor()
	add(black)

	for delay = 1, 7 do
		Timer():start(0.3 * delay, function()
			black.alpha = black.alpha - 0.15
			if black.alpha < 0 then
				remove(black)
			end
		end)
	end

	camHUD.visible, camNotes.visible = false, false

	Timer():start(2.1, function()
		add(senpaiEvil)
		senpaiEvil.alpha = 0
		add(white)
		for delay = 1, 7 do
			Timer():start(0.3 * delay, function()
				senpaiEvil.alpha = senpaiEvil.alpha + 0.15
				if senpaiEvil.alpha > 1 then
					senpaiEvil.alpha = 1

					Tween.tween(game.camera, {zoom = stage.camZoom - 0.2}, 2.4, {ease = Ease.sineIn})

					senpaiEvil:play('idle')
					game.sound.play(paths.getSound('gameplay/Senpai_Dies'), 1, false, true, function()
						remove(senpaiEvil)
						remove(red)
						remove(white)
						game.camera.zoom = stage.camZoom
						makeDialogueBox()
						camHUD.visible, camNotes.visible = true, true
						camHUD:flash(Color.WHITE, 4)
					end)
					Timer():start(2.4, function()
						game.camera.zoom = 1.4
						Tween.tween(game.camera, {zoom = stage.camZoom}, 1, {ease = Ease.circOut})
						game.camera:shake(0.005, 2.5)
					end)
					Timer():start(3.8, function()
						Tween.tween(white, {alpha = 1}, 1.2)
					end)
				end
			end)
		end
	end)
	if buttons then remove(buttons) end
end
