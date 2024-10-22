function event(params)
	local data, target = params.v
	switch(data.target, {
		[{"boyfriend", "bf", "player"}] = function() target = state.playerNotefield end,
		[{"dad", "opponent", "enemy"}] = function() target = state.enemyNotefield end,
		[{"girlfriend", "gf"}] = function() target = state.notefield[3] end
	})
	if target and target.character then

		target.character:playAnim(data.anim, data.force)
		target.character.lastHit = PlayState.conductor.time
	end
end
