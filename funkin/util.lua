local util = {}

function util.coolLerp(x, y, i, delta)
	return math.lerp(y, x, math.exp(-(delta or love.timer.getDelta()) * i))
end

function util.newGradient(dir, ...)
	local colorSize, meshData = select("#", ...) - 1, {}
	local off = dir:sub(1, 1):lower() == "v" and 1 or 2

	for i = 0, colorSize do
		local idx, color, x = i * 2 + 1, select(i + 1, ...), i / colorSize
		local r, g, b, a = color[1], color[2], color[3], color[4] or 1

		meshData[idx] = {x, x, x, x, r, g, b, a}
		meshData[idx + 1] = {x, x, x, x, r, g, b, a}

		for o = off, off + 2, 2 do
			meshData[idx][o], meshData[idx + 1][o] = 1, 0
		end
	end

	return love.graphics.newMesh(meshData, "strip", "static")
end

local time, clock, ms = "%d:%02d", "%d:%02d:%02d", "%.3f"
function util.formatTime(seconds, includeMS)
	local minutes = seconds / 60
	local str = minutes < 60 and time:format(minutes, seconds % 60) or
		clock:format(minutes / 60, minutes % 60, seconds % 60)
	if not includeMS then return str end
	return str .. ms:format(seconds - math.floor(seconds)):sub(2)
end

return util
