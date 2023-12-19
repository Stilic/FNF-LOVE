local duration
function postCreate()
    duration = PlayState.conductor.stepCrochet * 2 / 1100
end

function beat()
    Timer.tween(duration, state.iconP1, {y = state.iconP1.y - 20}, 'out-cubic', function()
        Timer.tween(duration, state.iconP1, {y = state.iconP1.y + 20}, 'in-cubic')
    end)
end

function update()
    local angleOfs = math.random(-15, 15)
	if state.health < 0.2 then
		state.iconP1.angle = angleOfs
	else
		state.iconP1.angle = 0
	end
end