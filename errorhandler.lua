local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

local og = love.errorhandler or love.errhand

function love.errorhandler(msg)
	collectgarbage()
	collectgarbage()

	if paths == nil then
		love.errorhandler = og
		love.errhand = og
		return og(msg)
	end

	local trace = debug.traceback()
	msg = tostring(msg)
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then return end
	end

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
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")
	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

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

	love.graphics.reset()
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()

	local menuDesat = paths.getImage("menus/menuDesat")
	local funkinLogo = paths.getImage("menus/splashscreen/FNFLOVE_logo")
	local fnfFont18 = paths.getFont("phantommuff.ttf", 18) or love.graphics.setNewFont(18)
	local fnfFont20 = paths.getFont("phantommuff.ttf", 35) or love.graphics.setNewFont(35)

	local bgMusic = paths.getMusic("pause/railways", "static")
	local missSfx = love.audio.newSource(paths.getSound("gameplay/missnote"..love.math.random(1,3)), "static")

	bgMusic:setLooping(true)
	bgMusic:setVolume(0.3)
	bgMusic:play()

	missSfx:setVolume(0.1)
	missSfx:play()

	local fullErrorText = p
	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end
	p = p .. "\nPress Ctrl+R to restart"

	local eventhandlers = {
		quit = function()
			return 1
		end,
		keypressed = function(key)
			if not love.keyboard.isDown("lctrl", "rctrl") then return end
			if love.system and key == "c" then
				love.system.setClipboardText(fullErrorText)
				p = p .. "\nCopied to clipboard!"
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
		null = function()end
	}

	local __error__, __center__ = "[ ERROR ]", "center"
	local prevGameW, prevGameH, gameW, gameH, prevP, prevWinX, prevWinY = -1, -1
	local menuDesatW, menuDesatH, funkinLogoW, funkinLogoH
	local scale1, scale2, hgameW, hgameH, retval, focused
	return function()
		love.event.pump()
		for name, a in love.event.poll() do
			retval = (eventhandlers[name] or eventhandlers.null)(a)
			if retval then return retval end
		end

		gameW, gameH = love.graphics.getPixelDimensions()
		focused = love.window.hasFocus()

		if gameW ~= prevGameW or gameH ~= prevGameH or p ~= prevP then
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

			prevGameW, prevGameH, prevP = gameW, gameH, p
		end

		bgMusic:setVolume(focused and 0.3 or 0.1)
		love.timer.sleep(focused and 0.1 or 1)
	end
end
love.errhand = love.errorhandler