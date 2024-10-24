local doof, music

function postCreate()
	local dialogue = love.filesystem.read(paths.getPath('songs/senpai/dialogue.txt')):split('\n')
	local black = Graphic(-100, -100, game.width * 2, game.height * 2, Color.BLACK)

	music = game.sound.play(paths.getMusic('gameplay/Lunchbox'), 0.8, true, true)

	doof = DialogueBox(dialogue)
	doof:setScrollFactor()
	doof.cameras = {state.camNotes}
	doof.finishThing = function()
		state:startCountdown()
		if state.buttons then state:add(state.buttons) end
		doof:destroy()
		close()
	end

	black:setScrollFactor()
	black.cameras = {state.camNotes}
	state:add(black)

	game.discardTransition()

	for delay = 1, 7 do
		Timer():start(0.3 * delay, function()
			black.alpha = black.alpha - 0.15
			if black.alpha < 0 then
				state:remove(black)
				state:add(doof)
			end
		end)
	end

	if state.buttons then state:remove(state.buttons) end
end

function postUpdate(dt)
	if controls:pressed('accept') and doof.isEnding then
		music:stop()
	end
end
