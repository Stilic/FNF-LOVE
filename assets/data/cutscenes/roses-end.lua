function create()
	local black = Graphic(-100, -100, game.width * 2, game.height * 2, Color.BLACK)
	black.alpha = 0
	black:setScrollFactor()
	add(black)

	Timer():start(0.5, function()
		camFollow:set((dad and dad.x or stage.dadPos.x) + 14,
			(dad and dad.y or stage.dadPos.y) + 4)
		game.camera:follow(camFollow, nil, 2.4)
		camZooming = false
		Tween.tween(game.camera, {zoom = 2}, 2, {ease = Ease.quadInOut})
		camHUD.visible, camNotes.visible = false, false
		for delay = 1, 7 do
			Timer():start(0.3 * delay, function() black.alpha = black.alpha + 0.15 end)
		end
	end)

	Timer():start(3, close)
end
