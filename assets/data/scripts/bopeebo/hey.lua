function beat()
	if curBeat ~= 79 and curBeat % 8 == 7 then
		state.gf:playAnim('cheer', true)
		state.gf.lastHit = math.floor(PlayState.conductor.time)
		state.boyfriend:playAnim('hey', true)
	end
end
