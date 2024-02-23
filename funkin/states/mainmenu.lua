local MainMenuState = State:extend("MainMenuState")

MainMenuState.curSelected = 1

function MainMenuState:enter()
	self.notCreated = false

	self.script = Script("data/scripts/states/mainmenu", false)
	local event = self.script:call("create")
	if event == Script.Event_Cancel then
		self.notCreated = true
		return
	end

	-- Update Presence
	if love.system.getDevice() == "Desktop" then
		Discord.changePresence({details = "In the Menus", state = "Main Menu"})
	end

	self.optionShit = {'story_mode', 'freeplay', 'donate', 'options'}

	self.selectedSomethin = false

	game.camera.target = {x = 0, y = 0}

	local yScroll = math.max(0.25 - (0.05 * (#self.optionShit - 4)), 0.1)
	self.menuBg = Sprite()
	self.menuBg:loadTexture(paths.getImage('menus/menuBG'))
	self.menuBg:setScrollFactor(0, yScroll)
	self.menuBg:setGraphicSize(math.floor(self.menuBg.width * 1.175))
	self.menuBg:updateHitbox()
	self.menuBg:screenCenter()
	self:add(self.menuBg)

	self.magentaBg = Sprite()
	self.magentaBg:loadTexture(paths.getImage('menus/menuBGMagenta'))
	self.magentaBg.visible = false
	self.magentaBg:setScrollFactor(0, yScroll)
	self.magentaBg:setGraphicSize(math.floor(self.magentaBg.width * 1.175))
	self.magentaBg:updateHitbox()
	self.magentaBg:screenCenter()
	self:add(self.magentaBg)

	self.menuItems = Group()
	self:add(self.menuItems)

	local scale = 1
	for i = 0, #self.optionShit - 1 do
		local offset = 98 - (math.max(#self.optionShit, 4) - 4) * 80
		local menuItem = Sprite(0, (i * 140) + offset)
		menuItem.scale = {x = scale, y = scale}
		menuItem:setFrames(paths.getSparrowAtlas(
			'menus/mainmenu/menu_' .. self.optionShit[i + 1]))
		menuItem:addAnimByPrefix('idle', self.optionShit[i + 1] .. ' basic', 24)
		menuItem:addAnimByPrefix('selected', self.optionShit[i + 1] .. ' white',
			24)
		menuItem:play('idle')
		menuItem.ID = (i + 1)
		menuItem:screenCenter('x')
		self.menuItems:add(menuItem)
		local scr = (#self.optionShit - 4) * 0.135
		if #self.optionShit < 6 then scr = 0 end
		menuItem:setScrollFactor(0, scr)
		menuItem:updateHitbox()
	end

	self.camFollow = {x = 0, y = 0}

	self.engineVersion = Text(12, game.height - 42,
		"FNF LÖVE v" .. Project.version,
		paths.getFont("vcr.ttf", 16), {255, 255, 255})
	self.engineVersion.antialiasing = false
	self.engineVersion.outline.width = 1
	self.engineVersion:setScrollFactor()
	self:add(self.engineVersion)

	self.funkinVersion = Text(12, game.height - 24, "Friday Night Funkin' v0.2.8",
		paths.getFont("vcr.ttf", 16), {255, 255, 255})
	self.funkinVersion.antialiasing = false
	self.funkinVersion.outline.width = 1
	self.funkinVersion:setScrollFactor()
	self:add(self.funkinVersion)

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = ButtonGroup()
		local w = 134

		local down = Button("down", 0, game.height - w)
		local up = Button("up", 0, down.y - w)
		local mods = Button("6", game.width - w, 0)
		mods:screenCenter("y")

		local enter = Button("return", game.width - w, down.y)
		enter.color = Color.GREEN
		local back = Button("escape", enter.x - w, down.y)
		back.color = Color.RED

		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(mods)

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self:changeSelection()

	self.script:call("postCreate")

	MainMenuState.super.enter(self)
end

function MainMenuState:update(dt)
	self.script:call("update", dt)
	if self.notCreated then return end

	if not self.selectedSomethin and self.throttles then
		if self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.down:check() then self:changeSelection(1) end

		if controls:pressed("back") then
			game.sound.play(paths.getSound('cancelMenu'))
			game.switchState(TitleState())
		end

		if controls:pressed("pick_mods") then
			game.switchState(ModsState())
		end

		if controls:pressed("accept") then
			self:enterSelection(self.optionShit[MainMenuState.curSelected])
		end

		if controls:pressed("debug_1") then
			self:openEditorMenu()
		end
	end

	game.camera.target.x, game.camera.target.y =
		util.coolLerp(game.camera.target.x, self.camFollow.x, 10, dt),
		util.coolLerp(game.camera.target.y, self.camFollow.y, 10, dt)

	for _, spr in ipairs(self.menuItems.members) do spr:screenCenter('x') end

	MainMenuState.super.update(self, dt)

	self.script:call("postUpdate", dt)
end

local triggerChoices = {
	story_mode = {true, function(self)
		game.switchState(StoryMenuState())
	end},
	freeplay = {true, function(self)
		game.switchState(FreeplayState())
	end},
	options = {false, function(self)
		local device = love.system.getDevice()
		if device == "Mobile" then
			self.buttons:set({visible = false})
			game.buttons.remove(self.buttons)
		end
		self.optionsUI = self.optionsUI or Options(true, function()
			self.selectedSomethin = false

			if device == "Desktop" then
				Discord.changePresence({details = "In the Menus", state = "Main Menu"})
			elseif device == "Mobile" then
				self.buttons:set({visible = true})
				game.buttons.add(self.buttons)
			end
		end)
		self.optionsUI:setScrollFactor()
		self.optionsUI:screenCenter()
		self.optionsUI.dontResetTab = true
		self:add(self.optionsUI)
		return false
	end},
	donate = {false, function(self)
		love.system.openURL('https://ninja-muffin24.itch.io/funkin')
		return true
	end}
}

function MainMenuState:openEditorMenu()
	self.selectedSomethin = true
	self.editorUI = self.editorUI or EditorMenu(function()
		self.selectedSomethin = false
	end)
	self.editorUI:setScrollFactor()
	self.editorUI:screenCenter()
	self:add(self.editorUI)
end

function MainMenuState:enterSelection(choice)
	local switch = triggerChoices[choice]
	self.selectedSomethin = true

	game.sound.play(paths.getSound('confirmMenu'))
	Flicker(self.magentaBg, switch[1] and 1.1 or 1, 0.15, false)

	for i, spr in ipairs(self.menuItems.members) do
		if MainMenuState.curSelected == spr.ID then
			Flicker(spr, 1, 0.05, not switch[1], false, function()
				self.selectedSomethin = not switch[2](self)
			end)
		elseif switch[1] then
			Timer.tween(0.4, spr, {alpha = 0}, 'out-quad', function()
				spr:destroy()
			end)
		end
	end
end

function MainMenuState:changeSelection(huh)
	if huh == nil then huh = 0 end
	game.sound.play(paths.getSound('scrollMenu'))

	MainMenuState.curSelected = MainMenuState.curSelected + huh
	MainMenuState.curSelected = (MainMenuState.curSelected - 1) % #self.optionShit + 1

	for _, spr in ipairs(self.menuItems.members) do
		spr:play('idle')
		spr:updateHitbox()

		if spr.ID == MainMenuState.curSelected then
			spr:play('selected')
			local add = 0
			if #self.menuItems > 4 then add = #self.menuItems * 8 end
			local x, y = spr:getGraphicMidpoint()
			self.camFollow.x, self.camFollow.y = x, y - add
			spr:centerOffsets()
		end
	end
end

function MainMenuState:leave()
	self.script:call("leave")
	if self.notCreated then return end

	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil

	if self.editorUI then self.editorUI:destroy() end
	self.editorUI = nil

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil

	self.script:call("postLeave")
end

return MainMenuState
