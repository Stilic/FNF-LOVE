function beat()
	if curBeat % 8 == 7 then
		state.gf:playAnim('cheer', true)
		state.gf.lastHit = PlayState.conductor.currentBeat
		if curBeat ~= 79 then
			state.boyfriend:playAnim('hey', true)
			state.boyfriend.lastHit = PlayState.conductor.currentBeat
		end
	end
end
