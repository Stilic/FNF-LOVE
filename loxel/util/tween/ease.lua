local Ease = {}

local function bounceOut(t)
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	elseif t < 2 / 2.75 then
		return 7.5625 * (t - 1.5 / 2.75) * (t - 1.5 / 2.75) + 0.75
	elseif t < 2.5 / 2.75 then
		return 7.5625 * (t - 2.25 / 2.75) * (t - 2.25 / 2.75) + 0.9375
	end
	return 7.5625 * (t - 2.625 / 2.75) * (t - 2.625 / 2.75) + 0.984375
end
local tweens = {
	quad = function(t) return t * t end,
	cube = function(t) return t * t * t end,
	quart = function(t) return t * t * t * t end,
	quint = function(t) return t * t * t * t * t end,
	sine = function(t) return 1 - math.cos(t * math.pi / 2) end,
	expo = function(t) return 2 ^ (10 * (t - 1)) end,
	circ = function(t) return 1 - math.sqrt(1 - t * t) end,
	back = function(t) return t * t * (2.70158 * t - 1.70158) end,
	elastic = function(t)
		t = t - 1
		return -(2 ^
			(10 * t)) * math.sin((t - (0.4 / (2 * math.pi) * math.asin(1))) * (2 * math.pi) / 0.4)
	end,
	bounce = function(t)
		return 1 - bounceOut(1 - t)
	end,
	bounceOut = bounceOut,
	smoothStep = function(t)
		t = t / 2
		return 2 * t * t * (t * -2 + 3)
	end,
	smootherStep = function(t)
		t = t / 2
		return 2 * t * t * t * (t * (t * 6 - 15) + 10)
	end
}

function Ease.linear(t) return t end

function Ease.out(f)
	return function(t, ...)
		return 1 - f(1 - t, ...)
	end
end

function Ease.inOut(f)
	return function(t, ...)
		local factor = t < 0.5 and t * 2 or (1 - t) * 2
		local result = f(factor, ...) / 2
		return (t < 0.5) and result or 1 - result
	end
end

for name, func in pairs(tweens) do
	if func ~= bounceOut then
		Ease[name .. "In"] = func
		Ease[name .. "Out"] = Ease.out(func)
		Ease[name .. "InOut"] = Ease.inOut(func)
	end
end

return Ease
