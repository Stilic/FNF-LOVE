local ButtonManager = {list = {}, active = {}}

function ButtonManager.remap(x, y)
	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)
	return (x - (winWidth - scale * game.width) / 2) / scale,
		(y - (winHeight - scale * game.height) / 2) / scale
end

function ButtonManager.add(o)
	if not table.find(ButtonManager.list, o) then
		table.insert(ButtonManager.list, o)
	end
end

function ButtonManager.reset()
	for i = #ButtonManager.list, 1, -1 do
		ButtonManager.list[i] = nil
	end
end

function ButtonManager.remove(o)
	table.delete(ButtonManager.list, o)
end

function ButtonManager.press(id, x, y)
	local X, Y = ButtonManager.remap(x, y)
	for _, group in ipairs(ButtonManager.list) do
		local button = group:checkPress(X, Y)
		if button then
			ButtonManager._press(button.key)
			ButtonManager.active[id] = button
			button.pressed = true
		end
	end
end

function ButtonManager.move(id, x, y)
	local X, Y = ButtonManager.remap(x, y)
	local active = ButtonManager.active[id]

	if not active then
		ButtonManager.press(id, x, y)
	else
		local found = false
		for _, group in ipairs(ButtonManager.list) do
			local button = group:checkPress(X, Y)
			if button then
				found = true
				if active ~= button then
					ButtonManager._release(active.key)
					active.pressed = false

					ButtonManager._press(button.key)
					ButtonManager.active[id] = button
					button.pressed = true
				end
			elseif active == button then
				button.pressed = false
			end
		end

		if not found then
			ButtonManager._release(active.key)
			for _, group in ipairs(ButtonManager.list) do
				local button = group:checkPress(X, Y)
				if active ~= button then
					active.pressed = false
				end
			end
			ButtonManager.active[id] = nil
		end
	end
end

function ButtonManager.release(id, x, y)
	local X, Y = ButtonManager.remap(x, y)
	local active = ButtonManager.active[id]
	if active then
		for _, group in ipairs(ButtonManager.list) do
			local button = group:checkPress(X, Y)
			if button then
				ButtonManager._release(active.key)
				active.pressed = false
			end
		end
		ButtonManager.active[id] = nil
	end
end

local keys, sc = {}, {}
function ButtonManager._press(key)
	keys[key], sc[love.keyboard.getScancodeFromKey(key)] = true, true
	love.keypressed(key)
end

function ButtonManager._release(key)
	keys[key], sc[love.keyboard.getScancodeFromKey(key)] = false, false
	love.keyreleased(key)
end

local _ogIsDown = love.keyboard.isDown
function love.keyboard.isDown(key)
	return keys[key] or _ogIsDown(key)
end

local _ogIsScancodeDown = love.keyboard.isScancodeDown
function love.keyboard.isScancodeDown(key)
	return sc[key] or _ogIsScancodeDown(key)
end

return ButtonManager
