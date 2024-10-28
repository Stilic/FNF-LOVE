function create()
	state.camHUD.visible, state.camNotes.visible = false, false

	state.camFollow:set(400, -2050)
	game.camera:snapToTarget()

	util.playSfx(paths.getSound('gameplay/Lights_Turn_On'))
	game.camera.zoom = 1.5

	local blackScreen = Graphic(0, 0,
		math.floor(game.width * 2), math.floor(game.height * 2), Color.BLACK)
	blackScreen:setScrollFactor()
	state:add(blackScreen)

	tween:tween(blackScreen, {alpha = 0}, 0.7, {
		onComplete = function()
			state:remove(blackScreen)
		end
	})

	Timer(timer):start(1, function()
		state.camHUD.visible, state.camNotes.visible = true, true
		tween:tween(game.camera, {zoom = state.stage.camZoom},
			1.2, {ease = Ease.quadInOut, onComplete = function() state:startCountdown() end})
	end)
end
