local function fromRGB(r, g, b)
	return {r / 255, g / 255, b / 255}
end

local function fromHEX(hex)
	return fromRGB(bit.band(bit.rshift(hex, 16), 0xFF),
		bit.band(bit.rshift(hex, 8), 0xFF),
		bit.band(hex, 0xFF))
end

---@class ColorTable
local colorTable = {
	BLACK   = fromHEX(0x000000),
	BLUE    = fromHEX(0x0000FF),
	BROWN   = fromHEX(0x8B4513),
	CYAN    = fromHEX(0x00FFFF),
	GRAY    = fromHEX(0x808080),
	GREEN   = fromHEX(0x008000),
	LIME    = fromHEX(0x00FF00),
	MAGENTA = fromHEX(0xFF00FF),
	ORANGE  = fromHEX(0xFFA500),
	PINK    = fromHEX(0xFFC0CB),
	PURPLE  = fromHEX(0x800080),
	RED     = fromHEX(0xFF0000),
	WHITE   = fromHEX(0xFFFFFF),
	YELLOW  = fromHEX(0xFFFF00)
}

---@class Color:ColorTable
local Color = {}

function Color.fromHEX(hex) return fromHEX(hex) end

function Color.fromRGB(...) return fromRGB(...) end

function Color.HSLtoRGB(h, s, l)
	local c = (1 - math.abs(l + l - 1)) * s
	local m = l - 0.5 * c
	local r, g, b = m, m, m
	if h == h then
		local h = (h % 1.0) * 6.0
		local x = c * (1 - math.abs(h % 2 - 1))
		c, x = c + m, x + m
		if h < 1 then
			r, g, b = c, x, m
		elseif h < 2 then
			r, g, b = x, c, m
		elseif h < 3 then
			r, g, b = m, c, x
		elseif h < 4 then
			r, g, b = m, x, c
		elseif h < 5 then
			r, g, b = x, m, c
		else
			r, g, b = c, m, x
		end
	end
	return r, g, b
end

function Color.RGBtoHSL(r, g, b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h, s, l = 0, 0, (max + min) / 2

	if max ~= min then
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, l
end

function Color.fromString(str)
	str = str:gsub("#", "")
	return fromRGB(tonumber('0x' .. str:sub(1, 2)),
		tonumber('0x' .. str:sub(3, 4)),
		tonumber('0x' .. str:sub(5, 6)))
end

function Color.convert(rgb)
	return {rgb[1] / 255,
		rgb[2] / 255,
		rgb[3] / 255}
end

function Color.saturate(rgb, amount)
	local h, s, l = Color.RGBtoHSL(rgb[1], rgb[2], rgb[3])
	s = math.min(1, math.max(0, s + amount))
	return {Color.HSLtoRGB(h, s, l)}
end

local lerp = function(...) return math.truncate(math.lerp(...), 3) end
function Color.lerp(x, y, i)
	return {lerp(x[1], y[1], i),
		lerp(x[2], y[2], i),
		lerp(x[3], y[3], i)}
end

function Color.lerpDelta(x, y, i, delta)
	i = math.exp(-(delta or game.dt) * i)
	return {lerp(y[1], x[1], i),
		lerp(y[2], x[2], i),
		lerp(y[3], x[3], i)}
end

function Color.vec4(tbl, ...)
	local args = {...}
	local fill = table.clone(tbl)

	local idx = 1
	for i = #tbl + 1, 4 do
		if idx <= #args then
			fill[i] = args[idx]
			idx = idx + 1
		else
			fill[i] = 0
		end
	end

	return fill[1], fill[2], fill[3], fill[4]
end

setmetatable(Color, {
	__index = function(tbl, key)
		tbl = colorTable[key]
		if tbl then return table.clone(tbl) end
	end
})

return Color
