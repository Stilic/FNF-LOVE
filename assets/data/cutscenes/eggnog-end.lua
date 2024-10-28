function create()
	Timer(timer):start(0.5, function()
		state.camHUD.visible, state.camNotes.visible = false, false

		util.playSfx(paths.getSound('gameplay/Lights_Shut_off'))
		game.camera.alpha = 0
	end)

	Timer(timer):start(3, function()
		close()
	end)
end
