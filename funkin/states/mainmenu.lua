local MainMenuState = State:extend("MainMenuState")

MainMenuState.curSelected = 1

function MainMenuState:enter()
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

	self.engineCreated = Text(12, game.height - 24, "Created By Stilic",
		paths.getFont("vcr.ttf", 16), {255, 255, 255})
	self.engineCreated.antialiasing = false
	self.engineCreated.outline.width = 1
	self.engineCreated:setScrollFactor()
	self:add(self.engineCreated)

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = ButtonGroup()
		self.buttons.width = 134
		self.buttons.height = 134

		local w = self.buttons.width

		local down = Button(2, game.height - w, 0, 0, "down")
		local up = Button(down.x, down.y - w, 0, 0, "up")

		local enter = Button(game.width - w, down.y, 0, 0, "return")
		enter.color = Color.GREEN
		local back = Button(enter.x - w, down.y, 0, 0, "escape")
		back.color = Color.RED

		local mods = Button(enter.x, game.height / 2 - w / 2, 0, 0, "6")

		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(enter)
		self.buttons:add(back)
		self.buttons:add(mods)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self:changeSelection()
end

function MainMenuState:update(dt)
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

	MainMenuState.super.update(self, dt)

	for _, spr in ipairs(self.menuItems.members) do spr:screenCenter('x') end
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
			self.buttons.visible = false
			game.buttons.remove(self.buttons)
		end
		self.optionsUI = self.optionsUI or Options(true, function()
			self.selectedSomethin = false

			if device == "Desktop" then
				Discord.changePresence({details = "In the Menus", state = "Main Menu"})
			elseif device == "Mobile" then
				self.buttons.visible = true
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

	if MainMenuState.curSelected > #self.optionShit then
		MainMenuState.curSelected = 1
	elseif MainMenuState.curSelected < 1 then
		MainMenuState.curSelected = #self.optionShit
	end

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
	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil

	if self.editorUI then self.editorUI:destroy() end
	self.editorUI = nil

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil
end

return MainMenuState
