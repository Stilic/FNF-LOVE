function postCreate()
	state.camZooming = false
end

local wasPlayer
function onCameraMove(event)
	local isPlayer = event.target.isPlayer
	if isPlayer == wasPlayer then return end
	wasPlayer = isPlayer
	Timer.tween((PlayState.conductor.stepCrotchet * 4 / 1000),
		game.camera, {zoom = isPlayer and 1 or 1.3}, "in-out-elastic")
end
