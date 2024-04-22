function onNoteHit(event)
	event.enableCamZooming = false
end

local target
function onCameraMove(event)
	if event.target == target then return end
	target = event.target

	Timer.tween((PlayState.conductor.stepCrotchet * 4 / 1000),
		game.camera, {zoom = target == "bf" and 1 or 1.3}, 'in-out-elastic')
end
