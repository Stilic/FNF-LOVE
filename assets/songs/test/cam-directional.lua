local moveVal = 10
function onCameraMove(event)
	local target = event.target == "bf" and "boyfriend" or event.target
	if state[target] then
		if state[target].curAnim.name == 'singLEFT' or state[target].curAnim.name == 'singLEFT-alt' then
			event.offset.x = event.offset.x + moveVal
		elseif state[target].curAnim.name == 'singDOWN' or state[target].curAnim.name == 'singDOWN-alt' then
			event.offset.y = event.offset.y - moveVal
		elseif state[target].curAnim.name == 'singUP' or state[target].curAnim.name == 'singUP-alt' then
			event.offset.y = event.offset.y + moveVal
		elseif state[target].curAnim.name == 'singRIGHT' or state[target].curAnim.name == 'singRIGHT-alt' then
			event.offset.x = event.offset.x - moveVal
		end
	end
end
