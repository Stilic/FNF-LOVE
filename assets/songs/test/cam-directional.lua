local offset = 10
function onCameraMove(event)
	local dir = event.target.dirAnim
	if dir == 0 then
		event.offset.x = event.offset.x - offset
	elseif dir == 1 then
		event.offset.y = event.offset.y + offset
	elseif dir == 2 then
		event.offset.y = event.offset.y - offset
	elseif dir == 3 then
		event.offset.x = event.offset.x + offset
	end
end
