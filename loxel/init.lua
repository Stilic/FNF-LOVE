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
TransitionData = require "loxel.transition.transitiondata"
Transition = require "loxel.transition.transition"
State = require "loxel.state"
Substate = require "loxel.substate"
Flicker = require "loxel.effects.flicker"
BackDrop = require "loxel.effects.backdrop"
Trail = require "loxel.effects.trail"
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

-- wip new ui
newUI = {
	UIButton = require "loxel.newui.button"
}

if flags.LoxelShowPrintsInScreen or love.system.getDevice() == "Mobile" then
	ScreenPrint = require "loxel.system.screenprint"
end

local function temp() return true end
local metatemp = setmetatable(table, {__index = function()return temp end})
game = {
	bound = {members = {}, scroll = {x = 0, y = 0}, super = metatemp},
	members = {},
	scroll = {x = 0, y = 0},
	super = metatemp,

	width = -1,
	height = -1,
	isSwitchingState = false,
	dt = 0,

	keys = require "loxel.input.keyboard",
	mouse = require "loxel.input.mouse",
	cameras = require "loxel.managers.cameramanager",
	buttons = require "loxel.managers.buttonmanager",
	sound = require "loxel.managers.soundmanager",
	save = require "loxel.util.save"
}
Classic.implement(game, Group)
Classic.implement(game.bound, Group)

local function triggerCallback(callback, ...) if callback then callback(...) end end

function game.getState(front) return front and Gamestate.current() or Gamestate.stack[1] end

function game.resetState(force, ...) game.switchState(getmetatable(game.getState())(...), force) end

function game.discardTransition() (game.getState() or metatemp):discardTransition() end

local requestedState = nil
function game.switchState(state, force)
	local stateOnCall = game.getState()
	if force or not stateOnCall then
		requestedState = state
		state.skipTransIn = true
		return
	end

	stateOnCall:startOutro(function()
		if game.getState() == stateOnCall then
			requestedState = state
		else
			print("startOutro callback was called after the state was switched. This will be ignored")
		end
	end)
end

function game.init(app, state, ...)
	local width, height = app.width, app.height
	game.width, game.height = width, height

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

	Camera.__init(love.graphics.newCanvas(width, height, {
		format = "normal",
		dpiscale = 1
	}))
	Transition.__init(width, height, game.bound)

	love.mouse.setVisible(false)

	game.cameras.reset()
	game.bound:add(game.cameras)

	triggerCallback(game.onPreStateEnter, state)

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
	game.keys.onPressed(...)
	callUIInput("keypressed", ...)
end

function game.keyreleased(...)
	game.keys.onReleased(...)
	callUIInput("keyreleased", ...)
end

function game.textinput(text) callUIInput("textinput", text) end

function game.wheelmoved(x, y) game.mouse.wheel = y end

function game.mousemoved(x, y) game.mouse.onMoved(x, y) end

function game.mousepressed(x, y, button) game.mouse.onPressed(button) end

function game.mousereleased(x, y, button) game.mouse.onReleased(button) end

function game.touchmoved(id, x, y, dx, dy, p, time) game.buttons.move(id, x, y, p, time) end

function game.touchpressed(id, x, y, dx, dy, p, time) game.buttons.press(id, x, y, p, time) end

function game.touchreleased(id, x, y, dx, dy, p, time) game.buttons.release(id, x, y, p, time) end

local function switch(state)
	Timer.clear()

	game.cameras.reset()
	game.sound.destroy()
	game.buttons.reset()

	triggerCallback(game.onPreStateSwitch, state)

	for _, s in ipairs(Gamestate.stack) do
		for _, o in ipairs(s.members) do
			if type(o) == "table" and o.destroy then o:destroy() end
		end
		if s.substate then
			Gamestate.pop(table.find(Gamestate.stack, s.substate))
			s.substate = nil
		end
	end

	triggerCallback(game.onPreStateEnter, state)

	Gamestate.switch(state)
	game.isSwitchingState = false

	triggerCallback(game.onPostStateSwitch, state)

	collectgarbage()
end
function game.update(real_dt)
	local dt = game.dt
	local low = math.min(math.log(1.101 + dt), 0.1)
	dt = real_dt - dt > low and dt + low or real_dt

	if requestedState ~= nil then
		dt, game.isSwitchingState = 0, true
		requestedState = switch(requestedState)
	end
	game.dt = dt

	for _, o in ipairs(Flicker.instances) do o:update(dt) end
	game.sound.update()

	for _, o in ipairs(game.bound.members) do if o.update then o:update(dt) end end
	for _, o in ipairs(game.members) do if o.update then o:update(dt) end end

	if not game.isSwitchingState then Gamestate.update(dt) end

	-- input must be here
	game.keys.update()
	game.mouse.update()
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
