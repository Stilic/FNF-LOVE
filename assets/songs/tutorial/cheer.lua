function postBeat()
	if curBeat >= 16 and curBeat < 48 then
		if curBeat % 16 == 14 then
			state.dad:playAnim('cheer', true)
			state.dad.lastHit = PlayState.conductor.currentBeat
		elseif curBeat % 16 == 15 then
			state.boyfriend:playAnim('hey', true)
		end
	end
end
