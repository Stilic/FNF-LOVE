local DialogueBox = require "funkin.gameplay.ui.dialoguebox"

local doof, music

function create()
	local dialogue = love.filesystem.read(paths.getPath('songs/senpai/dialogue.txt')):split('\n')
	local black = Sprite(-100, -100):make(game.width * 2, game.height * 2, { 0, 0, 0 })

	music = game.sound.play(paths.getMusic('gameplay/Lunchbox'), 0.8, true, true)

	doof = DialogueBox(dialogue)
	doof:setScrollFactor()
	doof.cameras = { state.camHUD }
	doof.finishThing = function ()
		state:startCountdown()
		close()
	end

	black:setScrollFactor()
	black.cameras = { state.camHUD }
	state:add(black)

	game.discardTransition()

	for delay = 1, 7 do
		Timer.after(0.3 * delay, function ()
			if black.alpha == 1 then
				game.camera.target.y = game.camera.target.y - 64
			end
			black.alpha = black.alpha - 0.15
			if black.alpha < 0 then
				state:remove(black)
				state:add(doof)
			end
		end)
	end
end

function postUpdate(dt)
	if controls:pressed('accept') and doof.isEnding then
		music:stop()
	end
end
