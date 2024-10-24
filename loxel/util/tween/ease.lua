local Ease = {}

local tweens = {
	quad = function(t) return t * t end,
	cube = function(t) return t * t * t end,
	quart = function(t) return t * t * t * t end,
	quint = function(t) return t * t * t * t * t end,
	sine = function(t) return 1 - math.cos(t * math.pi / 2) end,
	expo = function(t) return 2 ^ (10 * (t - 1)) end,
	circ = function(t) return 1 - math.sqrt(1 - t * t) end,

	smoothStep = function(t)
		t = t / 2
		return 2 * t * t * (t * -2 + 3)
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
		local factor = (t < 0.5) and t * 2 or (1 - t) * 2
		local result = f(factor, ...) / 2
		return (t < 0.5) and result or (1 - result)
	end
end

for name, func in pairs(tweens) do
	if type(func) == "function" then
		Ease[name .. "In"] = func
		Ease[name .. "Out"] = Ease.out(func)
		Ease[name .. "InOut"] = Ease.inOut(func)
	end
end

return Ease
