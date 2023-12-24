function create()
	state.camHUD.visible = false

	state.camFollow = { x = 400, y = -2050 }

	game.sound.play(paths.getSound('gameplay/Lights_Turn_On'))
	game.camera.zoom = 1.5
	game.camera.target = { x = state.camFollow.x, y = state.camFollow.y }

	local blackScreen = Sprite()
	blackScreen:make(math.floor(game.width * 2), math.floor(game.height * 2),
		{ 0, 0, 0 })
	blackScreen:setScrollFactor()
	state:add(blackScreen)

	Timer.tween(0.7, blackScreen, { alpha = 0 }, 'linear', function ()
		state:remove(blackScreen)
	end)

	Timer.after(1, function ()
		state.camHUD.visible = true
		Timer.tween(1.2, game.camera, { zoom = state.stage.camZoom }, 'in-out-quad',
			function () state:startCountdown() end)
	end)
end
