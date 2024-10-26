local bgMusic

function create()
	state.dad.alpha = 0
	state.camHUD.visible, state.camNotes.visible = false, false

	tankman = Sprite(state.dad.x + 100, state.dad.y)
	tankman:setFrames(paths.getSparrowAtlas('stages/tank/cutscenes/'
		.. paths.formatToSongPath(PlayState.SONG.song)))
	tankman:addAnimByPrefix('tightBars', 'TANK TALK 2', 24, false)
	tankman:play('tightBars', true)
	state:insert(table.find(state.members, state.dad) + 1, tankman)

	state.camFollow:set(state.dad.x + 380, state.dad.y + 170)
end

function postCreate()
	bgMusic = game.sound.load(paths.getMusic('gameplay/DISTORTO'), 0.5, true)
	bgMusic:play()

	game.sound.play(paths.getSound('gameplay/tankSong2'), ClientPrefs.data.vocalVolume / 100)
	Tween.tween(game.camera, {zoom = state.stage.camZoom * 1.2}, 4, {ease = Ease.quadInOut})

	Timer.wait(4, function()
		Tween.tween(game.camera, {zoom = state.stage.camZoom * 1.2 * 1.2}, 0.5, {ease = Ease.quadInOut})
		state.gf:playAnim('sad', true)
	end)

	Timer.wait(4.5, function()
		Tween.tween(game.camera, {zoom = state.stage.camZoom * 1.2}, 1, {ease = Ease.quadInOut})
	end)

	Timer.wait(11.5, function()
		tankman:destroy()
		state.dad.alpha = 1
		state.camHUD.visible, state.camNotes.visible = true, true

		Tween.tween(game.camera, {zoom = state.stage.camZoom},
			PlayState.conductor.crotchet / 1000 * 4.5, {ease = Ease.quadInOut})
		state:startCountdown()
	end)
end

function songStart()
	bgMusic:stop()
	close()
end
