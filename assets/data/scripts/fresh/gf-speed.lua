function beat()
	switch(curBeat, {
		[16] = function() state.gf.danceSpeed = 2 end,
		[48] = function() state.gf.danceSpeed = 1 end,
		[80] = function() state.gf.danceSpeed = 2 end,
		[112] = function() state.gf.danceSpeed = 1 end
	})
end
