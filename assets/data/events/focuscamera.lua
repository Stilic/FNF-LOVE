function event(params)
	local isTable = type(params.v) == "table"

	local n = isTable and params.v.char or tonumber(params.v)
	local ox, oy = isTable and params.v.x or 0, isTable and params.v.y or 0

	local notefield = state.notefields[n + 1]
	if notefield then state.camTarget = notefield.character end

	local mpx, mpy = state.camTarget:getMidpoint()
	ox, oy = ox + mpx, oy + mpy
	if state.camTarget == state.gf then
		ox = ox + state.stage.gfCam.x
		oy = oy + state.stage.gfCam.y
	elseif state.camTarget.isPlayer then
		ox = ox + state.stage.boyfriendCam.x - 100
		oy = oy + state.stage.boyfriendCam.y - 100
	else
		ox = ox + state.stage.dadCam.x + 150
		oy = oy + state.stage.dadCam.y - 100
	end

	if isTable and params.v.ease then
		switch(params.v.ease, {
			["CLASSIC"] = function() state:cameraMovement(ox, oy) end,
			["INSTANT"] = function() state:cameraMovement(ox, oy, "linear", 0) end,
			default = function()
				local ease = convertMethod(params.v.ease)
				local time = stepCrotchet * params.v.duration / 1000
				state:cameraMovement(ox, oy, ease, time)
			end
		})
	else
		state:cameraMovement(ox, oy)
	end
end

function convertMethod(input)
	input = input:gsub("(%w+)In", "in-%1")
	input = input:gsub("(%w+)Out", "out-%1")
	return input:lower()
end
