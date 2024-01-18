local util = {}

-- errors are there so you can found out which one thats using these
-- fuckass functions that are deprecated or incorrectly
function util.coolLerp(x, y, i, delta)
	if i < 1 then error("BAD, ALSO USE DELTA AS THE 4RD ARG IDIOT") end
	--if delta == nil then error("USE DELTA IDIOT") end
	return math.lerp(y, x, math.exp(-(delta or love.timer.getDelta()) * i))
	--return math.lerp(x, y, 1 - 1 / math.exp(i * 60 * love.timer.getDelta()))
end

function util.floorDecimal(value, decimals)
	error("BAD, USE MATH.TRUNCATE INSTEAD IDIOT")
end

function util.newGradient(dir, ...)
	local isHorizontal = true
	if dir == "vertical" then isHorizontal = false end

	local colorLen, meshData = select("#", ...), {}
	if isHorizontal then
		for i = 1, colorLen do
			local color = select(i, ...)
			local x = (i - 1) / (colorLen - 1)

			meshData[#meshData + 1] = {
				x, 1, x, 1, color[1], color[2], color[3], color[4] or 1
			}
			meshData[#meshData + 1] = {
				x, 0, x, 0, color[1], color[2], color[3], color[4] or 1
			}
		end
	else
		for i = 1, colorLen do
			local color = select(i, ...)
			local y = (i - 1) / (colorLen - 1)

			meshData[#meshData + 1] = {
				1, y, 1, y, color[1], color[2], color[3], color[4] or 1
			}
			meshData[#meshData + 1] = {
				0, y, 0, y, color[1], color[2], color[3], color[4] or 1
			}
		end
	end

	return love.graphics.newMesh(meshData, "strip", "static")
end

function util.removeExtension(filename)
	local nameWithoutExt = filename:match("(.+)%..+$")
	if nameWithoutExt then
		return nameWithoutExt
	else
		return filename
	end
end

function util.getFormattedTime(ms)
	local total = math.floor(ms)
	return string.format("%.f", math.floor(total / 60)) .. ":" ..
		string.format("%02.f", total % 60)
end

return util
