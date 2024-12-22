function postBeat()
	if not state.startingSong and curBeat >= 16 and curBeat < 48 and curBeat % 16 == 15 then
		local time = PlayState.conductor.time
		if state.dad then
			state.dad:playAnim('cheer', true)
			state.dad.lastHit = time
		end
		if state.boyfriend then
			state.boyfriend:playAnim('hey', true)
			state.boyfriend.lastHit = time
		end
	end
end
