function create()
	Timer.after(0.5, function ()
		state.camHUD.visible = false

		game.sound.play(paths.getSound('gameplay/Lights_Shut_off'))
		local blackScreen = Sprite(game.width * -0.5, game.height * -0.5)
		blackScreen:make(math.floor(game.width * 2), math.floor(game.height * 2),
			{ 0, 0, 0 })
		blackScreen:setScrollFactor()
		state:add(blackScreen)
	end)

	Timer.after(3, function () state:endSong(true) end)
end
