-- messy messy fucking codes
-- read with caution
local OS = love.system.getOS()

local restrictedfs = false
function love.filesystem.isRestricted()
	return restrictedfs
end

-- unrestrict the filesystem
if love.filesystem.isFused() or not love.filesystem.getInfo("assets") then
	if love.filesystem.mountFullPath then
		love.filesystem.mountFullPath(love.filesystem.getSourceBaseDirectory(), "")
	elseif OS ~= "Android" and OS ~= "IOS" then
		restrictedfs = true

		local lovefs = love.filesystem
		love.filesystem = setmetatable(require "lib.nativefs", {
			__index = lovefs
		})

		local function replace(func)
			return function(a, ...)
				return func(type(a) == "string" and love.filesystem.newFileData(a) or a,
					...)
			end
		end

		love.audio.newSource = replace(love.audio.newSource)
		love.graphics.newFont = replace(love.graphics.newFont)
		love.graphics.newCubeImage = replace(love.graphics.newCubeImage)
		love.graphics.newImage = replace(love.graphics.newImage)
		love.graphics.newImageFont = replace(love.graphics.newImageFont)
		love.graphics.setNewFont = replace(love.graphics.setNewFont)
		love.image.newImageData = replace(love.image.newImageData)
		love.sound.newSoundData = replace(love.sound.newSoundData)
	else
		restrictedfs = true
	end
end

-- NOTE, no matter how precision is, in windows 10 as of now (<=love 11)
-- will be always 12ms, unless its using SDL3 or CREATE_WAITABLE_TIMER_HIGH_RESOLUTION flag
local __step__, __quit__ = "step", "quit"
local dt, fps = 0, 0
local sleep = love.timer.sleep
local channel_event = love.thread.getChannel("event")
local channel_event_active = love.thread.getChannel("event_active")
local channel_event_tick = love.thread.getChannel("event_tick")
local thread_event_code, thread_event = [[require"love.event"; require"love.timer"
local pump, poll, getChannel = love.event.pump, love.event.poll(), love.thread.getChannel
local channel, active, tick = getChannel"event", getChannel"event_active", getChannel"event_tick"
local getTime, sleep, step = love.timer.getTime, love.timer.sleep, "step"

local t, s, clock, prev, v, push = {}, 0, getTime()
function push(i, a, ...) if a then t[i] = a; return push(i + 1, ...) end return i - 1 end
repeat v = active:pop(); if v == 0 then break elseif v == 1 then s = 0 end
	pcall(pump); prev, clock = clock, getTime()
	for name, a, b, c, d, e, f in poll do
		v = push(1, a, b, c, d, e, f); channel:push(name); channel:push(clock); channel:push(v);
		for i = 1, v do channel:push(t[i]) end
	end

	v = clock - prev; s = s + v; tick:clear(); tick:push(v)
	sleep(v < 0.001 and 0.001 or 0)
	collectgarbage(step)
until s > 1]]

local eventhandlers = {
	keypressed = function(t, b, s, r) return love.keypressed(b, s, r, t) end,
	keyreleased = function(t, b, s) return love.keyreleased(b, s, t) end,
	touchpressed = function(t, id, x, y, dx, dy, p) return love.touchpressed(id, x, y, dx, dy, p, t) end,
	touchmoved = function(t, id, x, y, dx, dy, p) return love.touchmoved(id, x, y, dx, dy, p, t) end,
	touchreleased = function(t, id, x, y, dx, dy, p) return love.touchreleased(id, x, y, dx, dy, p, t) end,
	joystickpressed = function(t, j, b) if love.joystickpressed then return love.joystickpressed(j, b, t) end end,
	joystickreleased = function(t, j, b) if love.joystickreleased then return love.joystickreleased(j, b, t) end end,
	gamepadpressed = function(t, j, b) if love.gamepadpressed then return love.gamepadpressed(j, b, t) end end,
	gamepadreleased = function(t, j, b) if love.gamepadreleased then return love.gamepadreleased(j, b, t) end end,
}
function love.run()
	local _, _, modes = love.window.getMode()
	love.FPScap, love.unfocusedFPScap = math.max(modes.refreshrate, 60), 8
	love.autoPause = flags.InitialAutoFocus
	love.parallelUpdate = flags.InitialParallelUpdate
	love.asyncInput, thread_event = flags.InitialAsyncInput, love.thread.newThread(thread_event_code)

	if love.math then love.math.setRandomSeed(os.time()) end
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	love.timer.step(); collectgarbage()

	local origin, clear, present = love.graphics.origin, love.graphics.clear, love.graphics.present
	local pump, poll, t, n, a, b = love.event.pump, love.event.poll(), {}, 0
	local focused, clock, nextdraw, cap = true, 0, 0, 0
	local prevFpsUpdate, sinceLastFps, frames = 0, 0, 0

	local function event(name, a, ...)
		if name == __quit__ and not love.quit() then
			channel_event:clear(); channel_event_active:clear(); channel_event_active:push(0)
			return a or 0, ...
		end
		--[[if name:sub(1,5) == "mouse" and name ~= "mousefocus" and (name ~= "mousemoved" or love.mouse.isDown(1, 2)) then
			love.handlers["touch"..name:sub(6)](0, a, ...)
		end]]
		if eventhandlers[name] then return eventhandlers[name](clock, a, ...) end
		return love.handlers[name](a, ...)
	end

	return function()
		a = love.asyncInput and focused
		if thread_event:isRunning() then
			channel_event_active:clear()
			channel_event_active:push(a and 1 or 0)
			a = channel_event:pop()
			while a do
				clock, b = channel_event:demand(), channel_event:demand()
				for i = 1, b do t[i] = channel_event:demand() end
				for i = b + 1, n do t[i] = nil end
				n, a, b = b, event(a, unpack(t))
				if a then return a, b end
				a = channel_event:pop()
			end
		elseif a then
			thread_event:start()
			channel_event:clear()
			channel_event_active:clear()
		end

		pump();
		for name, a, b, c, d, e, f in poll do
			a, b = event(name, a, b, c, d, e, f)
			if a then return a, b end
		end

		cap, b = 1 / (focused and love.FPScap or love.unfocusedFPScap), not love.parallelUpdate
		dt, clock = love.timer.step(), love.timer.getTime()
		if focused or not love.autoPause then
			love.update(dt);
			if love.graphics.isActive() and (b or clock > nextdraw - dt) then
				origin(); clear(love.graphics.getBackgroundColor()); love.draw(); present()
				nextdraw, sinceLastFps, frames = cap + clock, clock - prevFpsUpdate, frames + 1
				if sinceLastFps > 0.5 then
					fps, prevFpsUpdate, frames = math.round(frames / sinceLastFps), clock, 0
				end
			end
		end

		if love.window.hasFocus() then
			if b then sleep(cap - dt)
			else sleep(dt < 0.001 and 0.001 or 0) end
			collectgarbage(__step__)
			focused = true
		else
			if focused then collectgarbage(); collectgarbage()
			else collectgarbage(__step__) end
			focused = sleep(cap)
		end
	end
end

function love.handlers.fullscreen(f, t)
	love.fullscreen(f, t)
end

local _ogGetFPS = love.timer.getFPS

---@return number -- Returns the current ticks per second.
love.timer.getTPS = _ogGetFPS

---@return number -- Returns the current frames per second.
function love.timer.getFPS() return fps end

---@return number -- Returns the current inputs in second.
function love.timer.getInputs()
	if not love.asyncInput then return dt end
	local ips = channel_event_tick:peek()
	if not ips or ips > dt then return dt end
	return ips
end

-- fix a bug where love.window.hasFocus doesnt return the actual focus in Mobiles
local _ogSetFullscreen = love.window.setFullscreen
if OS == "Android" or OS == "IOS" then
	local _f = true
	function love.window.hasFocus()
		return _f
	end

	function love.handlers.focus(f)
		_f = f
		if love.focus then return love.focus(f) end
	end

	function love.window.setFullscreen()
		return false
	end
else
	function love.window.setFullscreen(f, t)
		if _ogSetFullscreen(f, t) then
			love.handlers.fullscreen(f, t)
			return true
		end
		return false
	end
end

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

local og = love.errorhandler or love.errhand

function love.errorhandler(msg)
	if channel_event_active then channel_event_active:push(0) end
	pcall(love.quit, true)

	if paths == nil then
		love.errorhandler = og
		love.errhand = og
		collectgarbage()
		collectgarbage()
		return og(msg)
	end

	msg = tostring(msg)
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then return end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then return end
	end

	local trace = debug.traceback()

	if utf8 == nil then utf8 = require("utf8") end

	local sanitizedmsg, err = {}, {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	table.insert(err, sanitizedmsg)
	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		l = l:gsub("stack traceback:", "Traceback\n")
		table.insert(err, l)
	end

	local p = table.concat(err, "\n"):gsub("\t", ""):gsub("%[string \"(.-)\"%]", "%1")
	local fullErrorText = p

	love.graphics.reset()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()

	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then love.mouse.setCursor() end
	end
	if love.joystick then
		for i, v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.window then
		_ogSetFullscreen(false)
		love.window.setDisplaySleepEnabled(true)
	end
	if love.audio then love.audio.stop() end
	if love.handlers then love.handlers = nil end

	collectgarbage()
	collectgarbage()

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end
	p = p .. "\nPress ESC to quit"
	p = p .. "\nPress Ctrl+R to restart"

	local menuDesat, funkinLogo, fnfFont18, fnfFont20
	local bgMusic, missSfx

	function firstPass()
		menuDesat = paths.getImage("menus/menuDesat")
		funkinLogo = paths.getImage("menus/splashscreen/FNFLOVE_logo")
		fnfFont18 = paths.getFont("phantommuff.ttf", 18) or love.graphics.setNewFont(18)
		fnfFont20 = paths.getFont("phantommuff.ttf", 35) or love.graphics.setNewFont(35)

		bgMusic = paths.getMusic("pause/railways", "static")
		missSfx = love.audio.newSource(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)), "static")

		bgMusic:setLooping(true)
		bgMusic:setVolume(0.7)
		bgMusic:play()

		missSfx:setVolume(0.4)
		missSfx:play()
	end

	local dontDraw = false
	local __error__, __center__, focused = "[ ERROR ]", "center"
	local scale1, scale2, gameW, gameH, hgameW, hgameH, retval
	local menuDesatW, menuDesatH, funkinLogoW, funkinLogoH
	local function draw(force)
		if not force and dontDraw then return end

		love.graphics.clear(0, 0, 0)

		hgameW, hgameH = gameW / 2, gameH / 2
		menuDesatW, menuDesatH = menuDesat:getWidth(), menuDesat:getHeight()
		funkinLogoW, funkinLogoH = funkinLogo:getWidth(), funkinLogo:getHeight()

		scale1 = math.max(gameW / menuDesatW, gameH / menuDesatH)
		scale2 = math.max(math.min(gameW, 1600) / funkinLogoW, math.min(gameH, 900) / funkinLogoH) * 0.7

		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.draw(menuDesat, hgameW, hgameH, 0, scale1, scale1, menuDesatW / 2, menuDesatH / 2)
		love.graphics.draw(funkinLogo, hgameW, hgameH, 0, scale2, scale2, funkinLogoW / 2, funkinLogoH / 2)

		love.graphics.setColor(1, 1, 1)

		love.graphics.setFont(fnfFont20)
		love.graphics.printf(__error__, 40, 40, love.graphics.getWidth() - 80, __center__)

		love.graphics.setFont(fnfFont18)
		love.graphics.printf(p, 40, 110, love.graphics.getWidth() - 80, __center__)

		love.graphics.present()
	end

	local function copyToClipboard()
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
		draw()
	end

	eventhandlers = {
		quit = function()
			return 1
		end,
		keypressed = function(key)
			if key == "escape" then return 1 end
			if not love.keyboard.isDown("lctrl", "rctrl") then return end
			if love.system and key == "c" then
				copyToClipboard()
			elseif key == "r" then
				return "restart"
			end
		end,
		touchpressed = function()
			local name = love.window.getTitle()
			if #name == 0 or name == "Untitled" then name = "Game" end

			local buttons = {"OK", "Cancel", "Restart"}
			if love.system then buttons[4] = "Copy to clipboard" end

			local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", buttons)
			if pressed == 1 then
				return 1
			elseif pressed == 3 then
				return "restart"
			elseif pressed == 4 then
				copyToClipboard()
			end
		end,
		focus = function(f)
			bgMusic:setVolume(f and 0.7 or 0.3)
		end,
		resize = function(w, h)
			gameW, gameH = w, h
			draw()
		end,
		displayrotated = function(force)
			gameW, gameH = love.graphics.getDimensions()
			draw(force)
		end
	}

	local __step__, name, a, b = "step"
	if love.system.getDevice() == "Mobile" then
		dontDraw = true

		local first, done = true, false
		return function()
			if first then
				first = false
				return
			end

			love.event.pump()
			for name, a in love.event.poll() do
				if eventhandlers[name] ~= nil then
					retval = eventhandlers[name](a)
					if retval then return retval end
				end
			end

			if not done then
				firstPass()
			end
			eventhandlers.displayrotated(true)

			done = true
			collectgarbage(__step__)
			sleep(0.1)
		end
	end

	firstPass()
	eventhandlers.displayrotated(true)

	return function()
		name, a, b = love.event.wait()
		if eventhandlers[name] ~= nil then
			collectgarbage(__step__)
			retval = (eventhandlers[name])(a, b)
			if retval then return retval end
		end
	end
end

love.errhand = love.errorhandler
