local modes = {
	minwidth = 160,
	minheight = 90,
	fullscreen = false,
	fullscreentype = "desktop",
	vsync = false,
	msaa = 0,
	resizable = true,
	centered = true,
	highdpi = false,
	usedpiscale = true,
}

-- make screen orientation locked for mobiles
local OS = love.system.getOS()
if OS == "Android" or OS == "iOS" then
	modes.resizable = false
	modes.fullscreen = true
end

love.window.setTitle(Project.title)
love.window.setMode(Project.width, Project.height, modes)
love.window.setIcon(love.image.newImageData(Project.icon))

local fpsFormat = "FPS: %d\nRAM: %s | VRAM: %s\nDRAWS: %d"
local fpsParallelFormat = "FPS: %d | UPDATE: %d \nRAM: %s | VRAM: %s\nDRAWS: %d"

local __step__, __quit__ = "step", "quit"
local consolas, real_fps = love.graphics.newFont('assets/fonts/consolas.ttf', 14), 0
function love.run()
	local _, _, modes = love.window.getMode()
	love.FPScap, love.unfocusedFPScap = math.max(modes.refreshrate, 60), 8
	love.showFPS = false
	love.autoPause = flags.InitialAutoFocus
	love.parallelUpdate = flags.InitialParallelUpdate

	if love.math then love.math.setRandomSeed(os.time()) end
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	love.timer.step()

	collectgarbage()
	collectgarbage(__step__)

	local _stats, _update, _fps, _ram, _vram, _text
	local function draw()
		love.graphics.origin()
		love.graphics.clear(love.graphics.getBackgroundColor())
		love.draw()

		if love.showFPS then
			_stats, _update = love.graphics.getStats(), love.timer.getUpdateFPS()
			_fps = math.min(love.parallelUpdate and real_fps or _update, love.FPScap)
			_ram, _vram = math.countbytes(collectgarbage("count") * 0x400), math.countbytes(_stats.texturememory)
			_text = love.parallelUpdate and
					fpsParallelFormat:format(_fps, _update, _ram, _vram, _stats.drawcalls) or
					fpsFormat:format(_fps, _ram, _vram, _stats.drawcalls)

			love.graphics.setColor(0, 0, 0, 0.5)
			love.graphics.printf(_text, consolas, 8, 8, 300, "left", 0)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf(_text, consolas, 6, 6, 300, "left", 0)
		end

		love.graphics.present()
	end

	local polledEvents, _defaultEvents = {}, {}
	local fpsUpdateFrequency, prevFpsUpdate, timeSinceLastFps, frames = 1, 0, 0, 0
	local firstTime, fullGC, focused, dt, real_dt, lowfps = true, true, false, 0
	local nextclock, clock, cap = 0, 0, 0

	return function()
		love.event.pump()
		table.merge(polledEvents, _defaultEvents)
		for name, a, b, c, d, e, f in love.event.poll() do
			if name == __quit__ and not love.quit() then
				return a or 0
			end
			_defaultEvents[name], polledEvents[name] = false, true
			love.handlers[name](a, b, c, d, e, f)
			--[[
			if name:sub(1,5) == "mouse" and name ~= "mousefocus" then
				love.handlers["touch"..name:sub(6)](a, b, c, d, e, f)
			end
			]]
		end

		real_dt = love.timer.step()
		lowfps = real_dt - dt > 0.04
		if not polledEvents.lowmemory and ((fullGC and not focused) or lowfps) then
			love.handlers.lowmemory()
			dt, fullGC = lowfps and dt + 0.04 or real_dt, false
		else
			dt, fullGC = real_dt, true
		end

		focused = firstTime or love.window.hasFocus()
		cap = 1 / (focused and love.FPScap or love.unfocusedFPScap)

		if focused or not love.autoPause then
			love.update(dt)
			if love.graphics.isActive() then
				if love.parallelUpdate then
					clock = love.timer.getTime()
					if clock + real_dt > nextclock then
						draw()
						nextclock = cap + clock
						timeSinceLastFps, frames = clock - prevFpsUpdate, frames + 1
						if timeSinceLastFps > fpsUpdateFrequency then
							real_fps, frames = math.round(frames / timeSinceLastFps), 0
							prevFpsUpdate = clock
						end
					end
				else
					draw()
				end
			end
		end

		collectgarbage(__step__)

		if not love.parallelUpdate or not focused then
			love.timer.sleep(cap - real_dt)
		else
			if real_dt < 0.001 then
				love.timer.sleep(0.001)
			end
		end
		firstTime = false
	end
end

local _ogGetFPS = love.timer.getFPS

---@return number -- Returns the current draws FPS.
function love.timer.getDrawFPS()
	return game.parallelUpdate and real_fps or _ogGetFPS()
end

---@return number -- Returns the current updates FPS.
love.timer.getUpdateFPS = _ogGetFPS

---@return number -- Returns the current frames per second.
love.timer.getFPS = love.timer.getDrawFPS

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

local og = love.errorhandler or love.errhand

function love.errorhandler(msg)
	if paths == nil then
		love.errorhandler = og
		love.errhand = og
		collectgarbage()
		collectgarbage()
		return og(msg)
	end

	msg = tostring(msg)
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

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

	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then love.mouse.setCursor() end
	end
	if love.joystick then
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.window then
		love.window.setDisplaySleepEnabled(true)
	end
	if love.audio then love.audio.stop() end
	if love.handlers then love.handlers = nil end

	collectgarbage()
	collectgarbage()

	love.graphics.reset()
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()

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
		missSfx = love.audio.newSource(paths.getSound("gameplay/missnote"..love.math.random(1,3)), "static")

		bgMusic:setLooping(true)
		bgMusic:setVolume(0.3)
		bgMusic:play()

		missSfx:setVolume(0.1)
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

	local eventhandlers = {
		quit = function()
			return 1
		end,
		keypressed = function(key)
			if not love.keyboard.isDown("lctrl", "rctrl") then return end
			if love.system and key == "c" then copyToClipboard()
			elseif key == "r" then
				return "restart"
			end
		end,
		touchpressed = function()
			local name = love.window.getTitle()
			if #name == 0 or name == "Untitled" then name = "Game" end

			local buttons = {"OK", "Cancel", "Restart"}
			if love.system then buttons[4] = "Copy to clipboard" end

			local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
			if pressed == 1 then return 1
			elseif pressed == 3 then return "restart"
			elseif pressed == 4 then copyToClipboard() end
		end,
		focus = function(f)
			bgMusic:setVolume(f and 0.3 or 0.1)
		end,
		resize = function(w, h)
			gameW, gameH = w, h
			draw()
		end,
		displayrotated = function(force)
			gameW, gameH = love.graphics.getPixelDimensions()
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
			love.timer.sleep(0.1)
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