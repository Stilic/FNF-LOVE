local bgFade, music

function create(_, kind)
	local color = kind == "thorns" and Color.BLACK or Color.convert({179, 223, 216})

	bgFade = Graphic(0, 0, game.width, game.height, color)
	bgFade.alpha = 0
	add(bgFade)

	if kind == "default" then
		music = game.sound.play(paths.getMusic('gameplay/Lunchbox'), 0.8, true, true)
	end

	Timer.wait(kind == "angry" and 1.5 or 2, function()
		for loop = 1, 5 do
			Timer.wait(0.83 * loop, function()
				bgFade.alpha = bgFade.alpha + (1 / 5) * 0.7
				if bgFade.alpha > 0.7 then
					bgFade.alpha = 0.7
				end
			end)
		end
		startDialogue()
	end)
end

function postCreate() return Event_Cancel end

function finishDialogue()
	util.playSfx(nextSound)
	if music then music:fade(1, 0.8, 0) end
	for loop = 1, 5 do
		Timer.wait(0.2 * loop, function()
			box.alpha = box.alpha - 1 / 5
			characters.alpha = box.alpha
			bgFade.alpha = bgFade.alpha - 1 / 5 * 0.7
		end)
	end
	Timer.wait(1, function()
		if music then music:stop() end
		closeDialogue()
	end)

	return Event_Cancel
end
