require "loxel.lib.override"
if flags == nil then flags = {} end

local Gamestate = require "loxel.lib.gamestate"
Classic = require "loxel.lib.classic"

Basic = require "loxel.basic"
Object = require "loxel.object"
Sound = require "loxel.sound"
Graphic = require "loxel.graphic"
Sprite = require "loxel.sprite"
Camera = require "loxel.camera"
Text = require "loxel.text"
TypeText = require "loxel.typetext"
Bar = require "loxel.ui.bar"
Group = require "loxel.group.group"
SpriteGroup = require "loxel.group.spritegroup"
State = require "loxel.state"
Substate = require "loxel.substate"
Flicker = require "loxel.effects.flicker"
ParallaxImage = require "loxel.effects.parallax"
Color = require "loxel.util.color"

Keyboard = require "loxel.input.keyboard"
Mouse = require "loxel.input.mouse"

Button = require "loxel.button"
ButtonGroup = require "loxel.group.buttongroup"

ui = {
	UIButton = require "loxel.ui.button",
	UICheckbox = require "loxel.ui.checkbox",
	UIDropDown = require "loxel.ui.dropdown",
	UIGrid = require "loxel.ui.grid",
	UIInputTextBox = require "loxel.ui.inputtextbox",
	UINumericStepper = require "loxel.ui.numericstepper",
	UITabMenu = require "loxel.ui.tabmenu",
	UISlider = require "loxel.ui.slider"
}

if flags.LoxelShowPrintsInScreen or love.system.getDevice() == "Mobile" then
	ScreenPrint = require "loxel.system.screenprint"
end

local function temp() return true end
local metatemp = setmetatable(table, {__index = function()return temp end})
game = {
	members = {},
	bound = {members = {}, super = metatemp},
	active = true,
	alive = true,
	exists = true,
	visible = true,
	canDraw = temp,
	_canDraw = temp,
	scroll = {x = 0, y = 0},
	super = metatemp,

	width = -1,
	height = -1,
	isSwitchingState = false,
	dt = 0,

	cameras = require "loxel.managers.cameramanager",
	buttons = require "loxel.managers.buttonmanager",
	sound = require "loxel.managers.soundmanager",
	save = require "loxel.util.save"
}
Classic.implement(game, Group)
Classic.implement(game.bound, Group)

local fade, cancelFade
local function fadeOut(time, callback)
	if fade and fade.timer then Timer.cancel(fade.timer) end
	if cancelFade then
		cancelFade = nil
		return
	end

	fade = {
		height = game.height * 2,
		texture = util.newGradient("vertical", {0, 0, 0}, {0, 0, 0},
			{0, 0, 0, 0})
	}
	fade.y = -fade.height
	fade.timer = Timer.tween(time, fade, {y = 0}, "linear", function()
		fade.texture:release()
		fade = nil
		if callback then callback() end
	end)
	fade.draw = function()
		love.graphics.draw(fade.texture, 0, fade.y, 0, game.width, fade.height)
	end
end
local function fadeIn(time, callback)
	if fade and fade.timer then Timer.cancel(fade.timer) end
	if cancelFade then
		cancelFade = nil
		return
	end

	fade = {
		height = game.height * 2,
		texture = util.newGradient("vertical", {0, 0, 0, 0}, {0, 0, 0},
			{0, 0, 0})
	}
	fade.y = -fade.height / 2
	fade.timer = Timer.tween(time * 2, fade, {y = fade.height}, "linear",
		function()
			fade.texture:release()
			fade = nil
			if callback then callback() end
		end)
	fade.draw = function()
		love.graphics.draw(fade.texture, 0, fade.y, 0, game.width, fade.height)
	end
end

local requestedState, skipTransition = nil, false
function game.switchState(state, skipTrans)
	requestedState = state

	if skipTrans == nil then
		skipTransition = false
	else
		skipTransition = skipTrans
	end
end

function game.resetState(skipTrans, ...)
	game.switchState(getmetatable(Gamestate.stack[1])(...), skipTrans)
end

function game.getState() return Gamestate.current() end

function game.discardTransition()
	if fade and fade.timer then Timer.cancel(fade.timer) end
	cancelFade = true
end

function game.init(app, state, ...)
	game.width = app.width
	game.height = app.height
	Camera.__init(love.graphics.newCanvas(app.width, app.height, {
		format = "normal",
		dpiscale = 1
	}))

	love.mouse.setVisible(false)

	if ScreenPrint then
		ScreenPrint.init(love.graphics.getDimensions())
		game:add(ScreenPrint)
		
		local ogprint = print
		function print(...)
			local v = {...}
			for i = 1, #v do v[i] = tostring(v[i]) end
			ScreenPrint.new(table.concat(v, ", "))
			ogprint(...)
		end
	end

	game.cameras.reset()

	Gamestate.switch(state(...))
end

local function callUIInput(func, ...)
	for _, o in ipairs(ui.UIInputTextBox.instances) do
		if o[func] then o[func](o, ...) end
	end
	for _, o in ipairs(ui.UINumericStepper.instances) do
		if o[func] then o[func](o, ...) end
	end
end
function game.keypressed(...)
	Keyboard.onPressed(...)
	callUIInput("keypressed", ...)
end

function game.keyreleased(...)
	Keyboard.onReleased(...)
	callUIInput("keyreleased", ...)
end

function game.textinput(text) callUIInput("textinput", text) end

function game.wheelmoved(x, y) Mouse.wheel = y end

function game.mousemoved(x, y) Mouse.onMoved(x, y) end

function game.mousepressed(x, y, button) Mouse.onPressed(button) end

function game.mousereleased(x, y, button) Mouse.onReleased(button) end

function game.touchmoved(id, x, y, dx, dy, p, time) game.buttons.move(id, x, y, p, time) end

function game.touchpressed(id, x, y, dx, dy, p, time) game.buttons.press(id, x, y, p, time) end

function game.touchreleased(id, x, y, dx, dy, p, time) game.buttons.release(id, x, y, p, time) end

local function switch(state)
	Timer.clear()

	game.cameras.reset()
	game.sound.destroy()
	game.buttons.reset()

	for _, s in ipairs(Gamestate.stack) do
		for _, o in ipairs(s.members) do
			if type(o) == "table" and o.destroy then o:destroy() end
		end
		if s.substate then
			Gamestate.pop(table.find(Gamestate.stack, s.substate))
			s.substate = nil
		end
	end

	if game.onPreStateSwitch then
		game.onPreStateSwitch(state)
	end
	Gamestate.switch(state)
	if game.onPostStateSwitch then
		game.onPostStateSwitch(state)
	end

	game.isSwitchingState = false

	collectgarbage()
end
function game.update(real_dt)
	local dt = game.dt
	local low = math.min(math.log(1.101 + dt), 0.1)
	dt = real_dt - dt > low and dt + low or real_dt
	game.dt = dt

	if requestedState ~= nil then
		game.isSwitchingState = true
		if not skipTransition then
			local state = requestedState
			fadeOut(0.7, function()
				switch(state)
				fadeIn(0.6)
			end)
		else
			switch(requestedState)
		end
		requestedState = nil
	end

	for _, o in ipairs(Flicker.instances) do o:update(dt) end
	game.cameras.update(dt)
	game.sound.update()

	if not game.isSwitchingState then Gamestate.update(dt) end
	for _, o in ipairs(game.bound.members) do if o.update then o:update(dt) end end
	for _, o in ipairs(game.members) do if o.update then o:update(dt) end end

	-- input must be here
	Keyboard.update()
	Mouse.update()
end

function game.resize(w, h)
	Gamestate.resize(w, h)
	for _, o in ipairs(game.bound.members) do
		if o.resize then o:resize(w, h) end
	end
	for _, o in ipairs(game.members) do
		if o.resize then o:resize(w, h) end
	end
end

function game.focus(f)
	game.sound.onFocus(f)
	Gamestate.focus(f)
	for _, o in ipairs(game.bound.members) do
		if o.focus then o:focus(f) end
	end
	for _, o in ipairs(game.members) do
		if o.focus then o:focus(f) end
	end
end

function game.fullscreen(f)
	Gamestate.fullscreen(f)
	for _, o in ipairs(game.bound.members) do
		if o.fullscreen then o:fullscreen(f) end
	end
	for _, o in ipairs(game.members) do
		if o.fullscreen then o:fullscreen(f) end
	end
end

function game.quit()
	Gamestate.quit()
	for _, o in ipairs(game.bound.members) do
		if o.quit then o:quit() end
	end
	for _, o in ipairs(game.members) do
		if o.quit then o:quit() end
	end
end

local _ogGetScissor, _ogSetScissor, _ogIntersectScissor
local _scX, _scY, _scW, _scH, _scSX, _scSY, _scvX, _scvY, _scvW, _scvH
local function getScissor() return _scvX, _scvY, _scvW, _scvH end
local function getRealScissor()
	return _scvX * _scSX + _scX, _scvY * _scSY + _scY, _scvW * _scSX, _scvH * _scSY
end

local function setScissor(x, y, w, h)
	_scvX, _scvY, _scvW, _scvH = x, y, w, h
	if not x then return _ogSetScissor() end
	_ogSetScissor(getRealScissor())
end

local function intersectScissor(x, y, w, h)
	if not _scvX then
		_scvX, _scvY, _scvW, _scvH = x, y, w, h
		_ogSetScissor(getRealScissor())
	end
	_scvX, _scvY = math.max(_scvX, x), math.max(_scvY, y)
	_scvW, _scvH = math.max(math.min(_scvX + _scvW, x + w) - _scvX, 0),
		math.max(math.min(_scvY + _scvH, y + h) - _scvY, 0)
	_ogSetScissor(getRealScissor())
end

local _scissors, _scissorn = {}, 0
function game.__pushBoundScissor(w, h, sx, sy)
	local idx = _scissorn * 6; _scissorn = _scissorn + 1
	_scissors[idx + 6], _scissors[idx + 5] = _scH, _scW
	_scissors[idx + 4], _scissors[idx + 3] = _scSY, _scSX
	_scissors[idx + 2], _scissors[idx + 1] = _scY, _scX
	_scSX, _scSY = math.abs(_scSX * sx), math.abs(_scSY * sy)
	_scX, _scW = (_scW - _scSX * math.abs(w)) / 2, math.abs(w)
	_scY, _scH = (_scH - _scSY * math.abs(h)) / 2, math.abs(h)
end

function game.__literalBoundScissor(w, h, sx, sy)
	local idx = _scissorn * 6; _scissorn = _scissorn + 1
	_scissors[idx + 6], _scissors[idx + 5] = _scH, _scW
	_scissors[idx + 4], _scissors[idx + 3] = _scSY, _scSX
	_scissors[idx + 2], _scissors[idx + 1] = _scY, _scX
	_scSX, _scSY = math.abs(sx), math.abs(sy)
	_scX, _scW = 0, math.abs(w)
	_scY, _scH = 0, math.abs(h)
end

function game.__popBoundScissor()
	_scissorn = _scissorn - 1; local idx = _scissorn * 4
	_scX, _scY = _scissors[idx + 1], _scissors[idx + 2]
	_scSX, _scSY = _scissors[idx + 3], _scissors[idx + 4]
	_scW, _scH = _scissors[idx + 5], _scissors[idx + 6]
end

function game.draw()
	Gamestate.draw()
	if fade then
		table.insert(game.cameras.list[#game.cameras.list].__renderQueue,
			fade.draw)
	end

	local grap, w, h = love.graphics, game.width, game.height
	local winW, winH = grap.getDimensions()
	local scale, xc, yc, wc, hc = math.min(winW / w, winH / h), grap.getScissor()

	_scW, _scH, _scSX, _scSY = winW, winH, scale, scale
	_scX, _scY = math.floor((winW - _scSX * w) / 2), math.floor((winH - _scSY * h) / 2)
	_scvX, _scvY, _scvW, _scvH = nil, nil, nil, nil

	_ogIntersectScissor, grap.intersectScissor = grap.intersectScissor, intersectScissor
	_ogGetScissor, grap.getScissor = grap.getScissor, getScissor
	_ogSetScissor, grap.setScissor = grap.setScissor, setScissor

	grap.push()
	grap.translate(_scX, _scY)
	grap.scale(scale)

	for _, c in ipairs(game.cameras.list) do c:draw() end
	for _, o in ipairs(game.bound.members) do
		if o.__render and (not o._canDraw or o:_canDraw()) then
			o:__render(game)
		end
	end

	grap.pop()

	_ogSetScissor(xc, yc, wc, hc)
	grap.getScissor, grap.setScissor = _ogGetScissor, _ogSetScissor
	grap.intersectScissor = _ogIntersectScissor

	for _, o in ipairs(game.members) do
		if o.__render and (not o._canDraw or o:_canDraw()) then
			o:__render(game)
		end
	end
end
