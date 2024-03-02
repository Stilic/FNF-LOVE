local source = (...) and (...):gsub('%.button$', '.') or ""
local Graphic = require(source .. "graphic")

---@class Button:Graphic
local Button = Graphic:extend("Button")
Button.instances = {}
Button.active = {}

function Button:new(key, x, y, width, height, color)
	Button.super.new(self, x, y)
	self.width = width or 134
	self.height = height or 134
	self.key = key

	if color == false then
		self.visible = false
		color = nil
	end
	self.color = color or Color.fromRGB(28, 26, 40)

	self.scrollFactor = {x = 0, y = 0}

	self.pressed = false
	self.pressedAlpha = 1
	self.releasedAlpha = 0.25

	self.alpha = self.releasedAlpha
	self.stunned = false

	self.lined = true
	self.pressedLineWidth = 4
	self.releasedLineWidth = 2

	self.line.width = self.releasedLineWidth
	self.config.round = {18, 18}

	if not table.find(Button.instances, self) then
		table.insert(Button.instances, self)
	end
end

function Button:update(dt)
	if not self.pressed then
		self.alpha = math.lerp(self.releasedAlpha, self.alpha,
			math.exp(-dt * 14.4))
		self.line.width = math.lerp(
			self.releasedLineWidth, self.line.width, math.exp(-dt * 12))
	else
		self.alpha = self.pressedAlpha
		self.line.width = self.pressedLineWidth
	end
end

function Button:destroy()
	Button.super.destroy(self)
	if table.find(Button.instances, self) then
		table.delete(Button.instances, self)
	end
	for id, actived in pairs(Button.active) do
		if actived == self then
			Button._release(self.key, love.timer.getTime())
			Button.active[id] = nil
			break
		end
	end
end

function Button:check(x, y)
	if not self.stunned and x >= self.x and
		x <= self.x + self.width and y >= self.y and
		y <= self.y + self.height then
		return self
	end
	return nil
end

function Button.remap(x, y)
	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)
	return (x - (winWidth - scale * game.width) / 2) / scale,
		(y - (winHeight - scale * game.height) / 2) / scale
end

function Button.reset()
	for _, o in ipairs(Button.instances) do
		o:destroy()
	end
end

function Button.press(id, x, y, p, time)
	local X, Y = Button.remap(x, y)
	for _, buttons in ipairs(Button.instances) do
		local button = buttons:check(X, Y)
		if button then
			Button._press(button.key, time)
			Button.active[id] = button
			button.pressed = true
		end
	end
end

function Button.move(id, x, y, p, time)
	local X, Y = Button.remap(x, y)
	local active = Button.active[id]

	if not active then
		Button.press(id, x, y, p, time)
	else
		local found = false
		for _, buttons in ipairs(Button.instances) do
			local button = buttons:check(X, Y)
			if button then
				found = true
				if active ~= button then
					Button._release(active.key, time)
					active.pressed = false

					Button._press(button.key, time)
					Button.active[id] = button
					button.pressed = true
				end
			elseif active == button then
				button.pressed = false
			end
		end

		if not found then
			Button._release(active.key, time)
			for _, buttons in ipairs(Button.instances) do
				local button = buttons:check(X, Y)
				if active ~= button then
					active.pressed = false
				end
			end
			Button.active[id] = nil
		end
	end
end

function Button.release(id, x, y, p, time)
	local X, Y = Button.remap(x, y)
	local active = Button.active[id]
	if active then
		for _, buttons in ipairs(Button.instances) do
			local button = buttons:check(X, Y)
			if button then
				Button._release(active.key, time)
				active.pressed = false
			end
		end
		Button.active[id] = nil
	end
end

local keys, sc = {}, {}
function Button._press(key, time)
	local code = love.keyboard.getScancodeFromKey(key)
	keys[key], sc[code] = true, true
	love.keypressed(key, code, false, time)
end

function Button._release(key, time)
	local code = love.keyboard.getScancodeFromKey(key)
	keys[key], sc[code] = false, false
	love.keyreleased(key, code, time)
end

local _ogIsDown = love.keyboard.isDown
function love.keyboard.isDown(key)
	return keys[key] or _ogIsDown(key)
end

local _ogIsScancodeDown = love.keyboard.isScancodeDown
function love.keyboard.isScancodeDown(key)
	return sc[key] or _ogIsScancodeDown(key)
end

return Button
