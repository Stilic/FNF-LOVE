local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	local font = love.graphics.setNewFont(14)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

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

    local menuDesat = paths.getImage('menus/menuDesat')
    local funkinLogo = paths.getImage('menus/splashscreen/FNFLOVE_logo')
    local fnfFont18 = paths.getFont('phantommuff.ttf', 18)
    local fnfFont20 = paths.getFont('phantommuff.ttf', 35)

    local bgMusic = paths.getMusic('pause/' .. ClientPrefs.data.pauseMusic)
    bgMusic:setLooping(true)
    bgMusic:setVolume(0.3)
    bgMusic:play()

    local missSfx = love.audio.newSource(paths.getSound('gameplay/missnote'..love.math.random(1,3)), "static")
    missSfx:setVolume(0.3)
    missSfx:play()

	local function draw()
		if not love.graphics.isActive() then return end
        local windowWidth, windowHeight = love.graphics.getDimensions()

        local scaleX1 = windowWidth / menuDesat:getWidth()
        local scaleY1 = windowHeight / menuDesat:getHeight()
        local scale1 = math.max(scaleX1, scaleY1)

        local scaleX2 = windowWidth / funkinLogo:getWidth()
        local scaleY2 = windowHeight / funkinLogo:getHeight()
        local scale2 = math.max(scaleX2, scaleY2)

		love.graphics.clear(0, 0, 0)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.draw(menuDesat, windowWidth / 2, windowHeight / 2, 0, scale1, scale1, menuDesat:getWidth() / 2, menuDesat:getHeight() / 2)
        love.graphics.draw(funkinLogo, windowWidth / 2, windowHeight / 2, 0, scale2 * 0.7, scale2 * 0.7, funkinLogo:getWidth() / 2, funkinLogo:getHeight() / 2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fnfFont20)
        love.graphics.printf('[ ERROR ]', 40, 40, love.graphics.getWidth() - 80, "center")
        love.graphics.setFont(fnfFont18)
		love.graphics.printf(p, 40, 110, love.graphics.getWidth() - 80, "center")
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end
end
