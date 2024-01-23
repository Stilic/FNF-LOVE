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

if love.system.getDevice() == "Mobile" or flags.LoxelShowPrintsInScreen then
	ScreenPrint = require "loxel.system.screenprint"
end

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

local function temp() return true end
game = {
	members = {},
	active = true,
	alive = true,
	exists = true,
	visible = true,
	canDraw = temp,
	_canDraw = temp,
	scroll = {x = 0, y = 0},
	super = setmetatable(table, {__index = function()return temp end}),

	width = -1,
	height = -1,
	isSwitchingState = false
}
Classic.implement(game, Group)

game.cameras = require "loxel.managers.cameramanager"
game.buttons = require "loxel.managers.buttonmanager"
game.sound = require "loxel.managers.soundmanager"
game.save = require "loxel.util.save"

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

function game.init(app, state)
	game.width = app.width
	game.height = app.height
	Camera.__init(love.graphics.newCanvas(app.width, app.height, {
		format = "normal",
		dpiscale = 1
	}))

	love.mouse.setVisible(false)

	local os = love.system.getOS()
	if os == "Android" or os == "iOS" then love.window.setFullscreen(true) end

	game.cameras.reset()

	Gamestate.switch(state())
	if ScreenPrint then
		ScreenPrint.init(love.graphics.getDimensions())
		game:add(ScreenPrint)
		
		local ogprint = print
		function print(...)
			ScreenPrint.new(table.concat({...}, ", "))
			ogprint(...)
		end
	end
end

local function callUIInput(func, ...)
	for _, o in pairs(ui.UIInputTextBox.instances) do
		if o[func] then o[func](o, ...) end
	end
	for _, o in pairs(ui.UINumericStepper.instances) do
		if o[func] then o[func](o, ...) end
	end
end
function game.keypressed(...)
	Keyboard.onPressed(...)
	callUIInput('keypressed', ...)
end

function game.keyreleased(...)
	Keyboard.onReleased(...)
	callUIInput('keyreleased', ...)
end

function game.textinput(text) callUIInput('textinput', text) end

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

	for _, s in pairs(Gamestate.stack) do
		for _, o in pairs(s.members) do
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
function game.update(dt)
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

	for _, o in pairs(Flicker.instances) do o:update(dt) end
	game.cameras.update(dt)
	game.sound.update()
	Keyboard.update()
	Mouse.update()

	if not game.isSwitchingState then Gamestate.update(dt) end
	for _, o in pairs(game.members) do
		if o.update then o:update(dt) end
	end
end

function game.draw()
	Gamestate.draw()
	if fade then
		table.insert(game.cameras.list[#game.cameras.list].__renderQueue,
			fade.draw)
	end
	for _, c in pairs(game.cameras.list) do c:draw() end
	for _, o in pairs(game.members) do
		if o.draw and (not o._canDraw or o:_canDraw()) then
			o:draw(game)
		end
	end
end

function game.resize(w, h)
	Gamestate.resize(w, h)
	for _, o in pairs(game.members) do
		if o.resize then o:resize(w, h) end
	end
end

function game.focus(f)
	game.sound.onFocus(f)
	Gamestate.focus(f)
	for _, o in pairs(game.members) do
		if o.focus then o:focus(f) end
	end
end

function game.fullscreen(f)
	Gamestate.fullscreen(f)
	for _, o in pairs(game.members) do
		if o.fullscreen then o:fullscreen(f) end
	end
end

function game.quit()
	Gamestate.quit()
	for _, o in pairs(game.members) do
		if o.quit then o:quit() end
	end
end
