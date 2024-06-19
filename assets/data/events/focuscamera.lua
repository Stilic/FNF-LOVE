function event(params)
	local n = type(params.v) == "number" and params.v or
		params.v.char

	local notefield = state.notefields[n + 1]
	if notefield then state.camTarget = notefield.character end

	state:cameraMovement()
end
