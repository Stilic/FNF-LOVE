function beat()
	if curBeat % 8 == 7 then
		state.gf:playAnim('cheer', true)
		state.gf.lastHit = math.floor(PlayState.conductor.time)
		if curBeat ~= 79 then
			state.boyfriend:playAnim('hey', true)
		end
	end
end
