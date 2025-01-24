local gameOverSound
function gameOverStart()
	local tankmanLines = 'jeffGameover-' .. love.math.random(1, 25)
	gameOverSound = paths.getSound('gameplay/jeffGameover/' .. tankmanLines)
end

function postGameOverStartLoop()
	game.sound.music:setVolume(ClientPrefs.data.musicVolume / 100 * 0.2)
	util.playSfx(gameOverSound, 1, false, true, function()
		game.sound.music:fade(1, game.sound.music:getVolume(), ClientPrefs.data.musicVolume / 100)
	end)
end

local noLastHit
function onNoteHit(event)
	if event.character == self then
		if PlayState.SONG.song:lower() == "stress" and event.note.type == "alt" then
			noLastHit = true
		end
	end
end

function postGoodNoteHit()
	if noLastHit then
		state.dad.lastHit = math.positive_infinity
		noLastHit = nil
	end
end
