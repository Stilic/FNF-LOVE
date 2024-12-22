function create()
	local black = Graphic(-100, -100, game.width * 2, game.height * 2, Color.BLACK)
	black.alpha = 0
	black:setScrollFactor()
	state:add(black)

	Timer(timer):start(0.5, function()
		state.camFollow:set((state.dad and state.dad.x or state.stage.dadPos.x) + 140,
			(state.dad and state.dad.y or state.stage.dadPos.y) + 40)
		state.camZooming = false
		Tween.tween(game.camera, {zoom = 1.5}, 1.5, {ease = Ease.quadInOut})
		state.camHUD.visible, state.camNotes.visible = false, false
		for delay = 1, 7 do
			Timer(timer):start(0.3 * delay, function() black.alpha = black.alpha + 0.15 end)
		end
	end)

	Timer(timer):start(3, function() close() end)
end
