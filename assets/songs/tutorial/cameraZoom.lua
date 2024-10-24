local function getZoom(isPlayer)
	return isPlayer and 1 or 1.3
end

function postCreate()
	state.camZooming = false
	game.camera.zoom = getZoom(state.camTarget.isPlayer)
end

local wasPlayer
function onCameraMove(event)
	if not state.startingSong then
		local isPlayer = event.target.isPlayer
		if isPlayer == wasPlayer then return end
		wasPlayer = isPlayer
		Tween.tween(game.camera, {zoom = getZoom(isPlayer)},
			PlayState.conductor.stepCrotchet * 4 / 1000, {ease = Ease.elasticInOut})
	end
end
