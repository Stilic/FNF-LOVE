function postCreate()
	local doof = DialogueBox("pixel", "angry", paths.formatToSongPath(PlayState.SONG.song))
	doof.cameras = {camNotes}
	doof.onFinish = close
	add(doof)

	util.playSfx(paths.getSound('gameplay/ANGRY_TEXT_BOX'))
	game.camera:shake(0.005, 0.8)
	camHUD:shake(0.001, 0.8)

	Timer():start(1.5, function()
		util.playSfx(paths.getSound('gameplay/ANGRY'))
		game.camera:shake(0.005, 0.1)
		camHUD:shake(0.001, 0.1)
	end)
end
