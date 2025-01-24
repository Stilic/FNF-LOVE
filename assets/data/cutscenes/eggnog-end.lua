function create()
	util.playSfx(paths.getSound('gameplay/Lights_Shut_off'))
	game.camera.alpha = 0.001
	state.camHUD.visible, state.camNotes.visible = false, false

	Timer():start(3, function()
		close()
	end)
end
