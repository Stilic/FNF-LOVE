local Color = {
	WHITE = {1, 1, 1},
	BLACK = {0, 0, 0},
	RED = {1, 0, 0},
	GREEN = {0, 1, 0},
	BLUE = {0, 0, 1}
}

function Color.HSL(h, s, l)
	if s<=0 then return l,l,l end
	h = (h/360)*6
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return r+m, g+m, b+m
end

function Color.HSLtoRGB(...)
	local r, g, b = Color.HSL(...)
	return r * 255, g * 255, b * 255
end

function Color.fromHSL(...)
	return {Color.HSL(...)}
end

function Color.fromString(str)
	str = str:gsub("#", "")
	return Color.fromRGB(tonumber('0x'..str:sub(1,2)),
						 tonumber('0x'..str:sub(3,4)),
						 tonumber('0x'..str:sub(5,6)))
end

function Color.fromRGB(r, g, b)
	return {r / 255, g / 255, b / 255}
end

function Color.convert(rgb)
	return {rgb[1] / 255,
			rgb[2] / 255,
			rgb[3] / 255}
end

return Color
