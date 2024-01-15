local DialogueBox = require "funkin.gameplay.ui.dialoguebox"

local doof

function create()
	local dialogue = love.filesystem.read(paths.getPath('songs/roses/dialogue.txt')):split('\n')

	doof = DialogueBox(dialogue)
	doof:setScrollFactor()
	doof.cameras = {state.camHUD}
	doof.finishThing = function()
		state:startCountdown()
		close()
	end

	game.sound.play(paths.getSound('gameplay/ANGRY_TEXT_BOX'))
	game.camera:shake(0.001, 0.8)
	state.camHUD:shake(0.001, 0.8)

	Timer.after(1.5, function()
		game.sound.play(paths.getSound('gameplay/ANGRY'))
		game.camera:shake(0.001, 0.1)
		state.camHUD:shake(0.001, 0.1)
		state:add(doof)
	end)
end
