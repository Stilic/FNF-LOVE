local doof, music

function postCreate()
	local black = Graphic(-100, -100, game.width * 2, game.height * 2, Color.BLACK)

	doof = DialogueBox("pixel", "default", paths.formatToSongPath(PlayState.SONG.song))
	doof.cameras = {camNotes}
	doof.onFinish = close
	add(doof)

	black:setScrollFactor()
	black.cameras = {camNotes}
	add(black)

	game.discardTransition()

	for delay = 1, 7 do
		Timer():start(0.3 * delay, function()
			black.alpha = black.alpha - 0.15
			if black.alpha < 0 then
				remove(black)
			end
		end)
	end

	if buttons then remove(buttons) end
end

function pause() return Event_Cancel end
