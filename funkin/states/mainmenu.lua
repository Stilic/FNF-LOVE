local MainMenuState = State:extend("MainMenuState")

MainMenuState.curSelected = 1

function MainMenuState:enter()
	-- Update Presence
	if love.system.getDevice() == "Desktop" then
		Discord.changePresence({details = "In the Menus"})
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

	if love.system.getDevice() == "Mobile" then
		self.buttons = ButtonGroup()
		self.buttons.type = "roundrect"
		self.buttons.lined = true
		self.buttons.width = 134
		self.buttons.height = 134

		local w = self.buttons.width

		local down = Button(2, game.height - w, 0, 0, "down")
		local up = Button(down.x, down.y - w, 0, 0, "up")

		local enter = Button(game.width - w, down.y, 0, 0, "return")
		enter:setColor(Color.GREEN)
		local back = Button(enter.x - w, down.y, 0, 0, "escape")
		back:setColor(Color.RED)

		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self:changeSelection()
end

function MainMenuState:update(dt)
	game.camera.target.x, game.camera.target.y =
		util.coolLerp(game.camera.target.x, self.camFollow.x, 0.2),
		util.coolLerp(game.camera.target.y, self.camFollow.y, 0.2)

	if not self.selectedSomethin then
		if controls:pressed('ui_up') then self:changeSelection(-1) end
		if controls:pressed('ui_down') then self:changeSelection(1) end

		if controls:pressed("back") then
			game.sound.play(paths.getSound('cancelMenu'))
			game.switchState(TitleState())
		end

		if controls:pressed("pick_mods") then
			game.switchState(ModsState())
		end

		if controls:pressed("accept") then
			local selected = self.optionShit[MainMenuState.curSelected]
			if selected == 'donate' then
				love.system.openURL('https://ninja-muffin24.itch.io/funkin')
			else
				self.selectedSomethin = true
				game.sound.play(paths.getSound('confirmMenu'))

				Flicker(self.magentaBg, 1.1, 0.15, false)

				for i, spr in ipairs(self.menuItems.members) do
					if MainMenuState.curSelected ~= spr.ID then
						Timer.tween(0.4, spr, {alpha = 0}, 'out-quad',
							function ()
								spr:destroy()
							end)
					else
						Flicker(spr, 1, 0.06, false, false, function ()
							local daChoice =
								self.optionShit[MainMenuState.curSelected]

							if daChoice == 'story_mode' then
								game.switchState(StoryMenuState())
							elseif daChoice == 'freeplay' then
								game.switchState(FreeplayState())
							elseif daChoice == 'options' then
								game.switchState(OptionsState())
							end
						end)
					end
				end
			end
		end
	end

	MainMenuState.super.update(self, dt)

	for _, spr in ipairs(self.menuItems.members) do spr:screenCenter('x') end
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

return MainMenuState
