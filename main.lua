io.stdout:setvbuf("no")

require "lib.override"
require "lib.autobatch"

Object = require "lib.classic"
push = require "lib.push"
Timer = require "lib.timer"
Gamestate = require "lib.gamestate"

paths = require "game.paths"
util = require "game.util"

Script = require "game.script"

Camera = require "game.camera"

Sprite = require "game.sprite"
Group = require "game.group"

Note = require "game.gameplay.ui.note"
Receptor = require "game.gameplay.ui.receptor"

Stage = require "game.gameplay.stage"
Character = require "game.gameplay.character"

State = require "game.state"
TitleState = require "game.states.title"
PlayState = require "game.states.play"

local gamePaused, firstTime = false, true

local function onBeat(b) Gamestate.beat(b) end

function setMusic(source)
	music = source:onBeat(onBeat)
	return source
end

function resetMusic()
	setMusic(paths.getMusic("freakyMenu")):setBPM(102).looping = true
end

controls = (require "lib.baton").new({
	controls = {
		ui_left = { "key:left", "key:a", "axis:leftx-", "button:dpleft" },
		ui_down = { "key:down", "key:s", "axis:lefty+", "button:dpdown" },
		ui_up = { "key:up", "key:w", "axis:lefty-", "button:dpup" },
		ui_right = { "key:right", "key:d", "axis:leftx+", "button:dpright" },

		note_left = {
			"key:left", "key:a", "axis:leftx-", "button:dpleft", "button:x"
		},
		note_down = {
			"key:down", "key:s", "axis:lefty+", "button:dpdown", "button:a"
		},
		note_up = { "key:up", "key:l", "axis:lefty-", "button:dpup", "button:y" },
		note_right = {
			"key:right", "key:p", "axis:leftx+", "button:dpright", "button:b"
		},

		accept = { "key:space", "key:return", "button:a", "button:start" },
		back = { "key:backspace", "key:escape", "button:b" },
		pause = { "key:return", "key:escape", "button:start" },
		reset = { "key:r", "button:leftstick" }
	},
	joystick = love.joystick.getJoysticks()[1]
})

local fade, fadeTimer
function fadeOut(time, callback)
	if fadeTimer then Timer.cancel(fadeTimer) end

	fade = {
		height = push.getHeight() * 2,
		texture = util.newGradient("vertical", { 0, 0, 0 }, { 0, 0, 0 },
			{ 0, 0, 0, 0 })
	}
	fade.y = -fade.height
	fadeTimer = Timer.tween(time, fade, { y = 0 }, "linear", function()
		fade.texture:release()
		fade = nil
		if callback then callback() end
	end)
end

function fadeIn(time, callback)
	if fadeTimer then Timer.cancel(fadeTimer) end

	fade = {
		height = push.getHeight() * 2,
		texture = util.newGradient("vertical", { 0, 0, 0, 0 }, { 0, 0, 0 },
			{ 0, 0, 0 })
	}
	fade.y = -fade.height / 2
	fadeTimer = Timer.tween(time * 2, fade, { y = fade.height }, "linear",
		function()
			fade.texture:release()
			fade = nil
			if callback then callback() end
		end)
end

isSwitchingState = false
function switchState(state, transition)
	if transition == nil then transition = true end

	isSwitchingState = true

	local function switch()
		Timer.clear()
		for _, o in pairs(Gamestate.current()) do
			if type(o) == "table" and o.destroy then o:destroy() end
		end
		paths.clearCache()
		Gamestate.switch(state)
		isSwitchingState = false
		collectgarbage()
	end

	if transition then
		fadeOut(0.7, function()
			switch()
			fadeIn(0.6)
		end)
	else
		switch()
	end
end

function love.load()
	love.mouse.setVisible(false)

	local os = love.system.getOS()
	if os == "Android" or os == "iOS" then love.window.setFullscreen(true) end

	local dimensions = require "dimensions"
	push.setupScreen(dimensions.width, dimensions.height, { upscale = "normal" })
	love.graphics.setFont(paths.getFont("vcr.ttf", 18))

	switchState(TitleState(), false)
end

function love.resize(width, height)
	push.resize(width, height)
	Gamestate.resize(width, height)
end

function love.keypressed(...) controls:onKeyPress(...) end

function love.keyreleased(...) controls:onKeyRelease(...) end

function love.update(dt)
	if not firstTime and gamePaused then return end
	if firstTime then firstTime = false end

	dt = math.min(dt, 1 / 30)

	for _, o in pairs(paths.cache) do
		if o.object.update then o.object:update(dt) end
	end

	controls:update()
	Timer.update(dt)
	Gamestate.update(dt)
end

function love.draw()
	push.start()

	Gamestate.draw()

	if fade then
		love.graphics.draw(fade.texture, 0, fade.y, 0, push:getWidth(),
			fade.height)
	end

	push.finish()
end

function love.focus(f)
	gamePaused = not f
	for _, o in pairs(paths.cache) do
		if o.type == "source" then
			if gamePaused then
				o.lastPause = o.object:isPaused()
				o.object:pause()
			else
				if not o.lastPause and not o.object:isFinished() then
					o.object:resume()
				end
				o.lastPause = nil
			end
		end
	end
end
