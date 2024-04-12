local moveVal = 10
local target = ""

function onCameraMove(event)
	target = event.target == "bf" and "boyfriend" or event.target
end

function postUpdate(dt)
	if state[target] then
		if state[target].curAnim.name == 'singLEFT' or state[target].curAnim.name == 'singLEFT-alt' then
			state.camFollow.x = state.camFollow.x - moveVal
		elseif state[target].curAnim.name == 'singDOWN' or state[target].curAnim.name == 'singDOWN-alt' then
			state.camFollow.y = state.camFollow.y + moveVal
		elseif state[target].curAnim.name == 'singUP' or state[target].curAnim.name == 'singUP-alt' then
			state.camFollow.y = state.camFollow.y - moveVal
		elseif state[target].curAnim.name == 'singRIGHT' or state[target].curAnim.name == 'singRIGHT-alt' then
			state.camFollow.x = state.camFollow.x + moveVal
		end
	end
end
