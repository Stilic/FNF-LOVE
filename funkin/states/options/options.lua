local OptionsState = State:extend("OptionsState")

local tabs = {
	Gameplay = require "funkin.states.options.gameplay",
	Graphic = require "funkin.states.options.graphic",
	Controls = require "funkin.states.options.controls"
}

function OptionsState:enter()
	-- Update Presence
	if love.system.getDevice() == "Desktop" then
		Discord.changePresence({details = "In the Menus"})
	end

	self.curTab = 1
	self.curSelect = 1
	self.controls = table.clone(ClientPrefs.controls)
	self.changingOption = false

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuBGBlue'))
	self.bg.color = {0.5, 0.5, 0.5}
	self.bg:setScrollFactor()
	self.bg:screenCenter()
	self:add(self.bg)

	self.scrollCam = Camera()
	self.scrollCam.target = {x = game.width / 2, y = game.height / 2}
	game.cameras.add(self.scrollCam, false)

	self.camFollow = {x = game.width / 2, y = game.height / 2}

	self.optionsTab = {
		'Gameplay',
		'Graphic',
		'Controls'
	}

	self.titleTabBG = Sprite(0, 20):make(game.width * 0.8, 65, {0, 0, 0})
	self.titleTabBG.alpha = 0.7
	self.titleTabBG:screenCenter('x')
	self.titleTabBG.cameras = {self.scrollCam}
	self:add(self.titleTabBG)

	self.tabBG = Sprite(0, 105):make(game.width * 0.8, game.height * 0.75,
		{0, 0, 0})
	self.tabBG.alpha = 0.7
	self.tabBG:screenCenter('x')
	self.tabBG.cameras = {self.scrollCam}
	self:add(self.tabBG)

	self.optionsCursor = Sprite():make((game.width * 0.78), 39, {1, 1, 1})
	self.optionsCursor.alpha = 0.1
	self.optionsCursor.visible = false
	self.optionsCursor:screenCenter('x')
	self.optionsCursor.cameras = {self.scrollCam}
	self:add(self.optionsCursor)

	self.curBindSelect = 1

	self.controlsCursor = Sprite(game.width / 2 + 5):make(240, 39, {1, 1, 1})
	self.controlsCursor.alpha = 0.2
	self.controlsCursor.visible = false
	self.controlsCursor.cameras = {self.scrollCam}
	self:add(self.controlsCursor)

	self.titleTxt = Text(0, 30, '', paths.getFont('phantommuff.ttf', 40),
		{1, 1, 1}, "center", game.width)
	self.titleTxt.cameras = {self.scrollCam}
	self:add(self.titleTxt)

	self.allTabs = Group()
	self.allTabs.cameras = {self.scrollCam}
	self:add(self.allTabs)

	self.textGroup = Group()
	self.textGroup.cameras = {self.scrollCam}
	self:add(self.textGroup)

	self.spriteGroup = Group()
	self.spriteGroup.cameras = {self.scrollCam}
	self:add(self.spriteGroup)

	self.timerHold = 0
	self.waiting_input = false
	self.block_input = false
	self.onTab = false

	self.blackFG = Sprite():make(game.width, game.height, {0, 0, 0})
	self.blackFG.alpha = 0
	self.blackFG.cameras = {self.scrollCam}
	self.blackFG:setScrollFactor()
	self:add(self.blackFG)

	self.waitInputTxt = Text(0, 0, 'Rebinding..',
		paths.getFont('phantommuff.ttf', 60), {1, 1, 1},
		"center", game.width)
	self.waitInputTxt:screenCenter('y')
	self.waitInputTxt.visible = false
	self.waitInputTxt.cameras = {self.scrollCam}
	self.waitInputTxt:setScrollFactor()
	self:add(self.waitInputTxt)

	self.hitboxdown = {y = game.width - 65, height = 65}
	self.hitboxup = {y = -65, height = 65}

    if love.system.getDevice() == "Mobile" then
        local camButtons = Camera()
        game.cameras.add(camButtons, false)

		self.buttons = ButtonGroup()
		self.buttons.type = "roundrect"
		self.buttons.lined = true
		self.buttons.width = 134
		self.buttons.height = 134
        self.buttons.cameras = {camButtons}

		local w = self.buttons.width

		local left = Button(2, game.height - w, 0, 0, "left")
		local up = Button(left.x + w, left.y - w, 0, 0, "up")
		local down = Button(up.x, left.y, 0, 0, "down")
		local right = Button(down.x + w, left.y, 0, 0, "right")

		local enter = Button(game.width - w, left.y, 0, 0, "return")
		enter:setColor(Color.GREEN)
		local back = Button(enter.x - w, left.y, 0, 0, "escape")
		back:setColor(Color.RED)

		self.buttons:add(left)
		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(right)

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self:reset_Tabs()
	self:changeTab()
end

function OptionsState:reset_Tabs()
	for _, idk in ipairs({self.allTabs, self.textGroup,
		self.spriteGroup}) do
		idk:clear()
	end

	for _, tab in next, self.optionsTab do
		tabs[tab].add(self)
	end

	for _, idk in ipairs({self.allTabs, self.textGroup, self.spriteGroup}) do
		for _, grp in ipairs(idk.members) do
			for _, obj in ipairs(grp.members) do
				obj.visible = (grp.name == self.optionsTab[self.curTab])
				if grp.isLines then
					obj:make(2, self.tabBG.height - 24, {255, 255, 255})
				end
			end
		end
	end
end

function OptionsState:update(dt)
	OptionsState.super.update(self, dt)

	self.scrollCam.target.x, self.scrollCam.target.y =
		util.coolLerp(self.scrollCam.target.x, self.camFollow.x, 0.2),
		util.coolLerp(self.scrollCam.target.y, self.camFollow.y, 0.2)

	if self.onTab then
		self.hitboxdown.y = self.scrollCam.scroll.y + (game.height - 65)
		if self.camFollow.y > game.height / 2 then
			self.hitboxup.y = self.scrollCam.scroll.y + (game.height / 2 - 65)
		else
			self.camFollow.y = game.height / 2
			self.hitboxup.y = -65
		end
		if self.optionsCursor.y > self.hitboxdown.y then
			self.camFollow.y = self.optionsCursor.y - (game.height - 463)
		elseif (self.optionsCursor.y + self.optionsCursor.height) <
			(self.hitboxup.y + self.hitboxup.height) then
			self.camFollow.y = self.optionsCursor.y
		end
	end

	if controls:pressed('back') then
		if self.block_input then
			self.block_input = false
			return
		end

		game.sound.play(paths.getSound('cancelMenu'))
		if self.waiting_input then
			self.waiting_input = false
			self.blackFG.alpha = 0
			self.waitInputTxt.visible = false
		elseif self.onTab then
			if self.changingOption then
				if self.optionsTab[self.curTab] == 'Gameplay' or
					self.optionsTab[self.curTab] == 'Graphic' then
					tabs[self.optionsTab[self.curTab]].selectOption(self.curSelect)
					self:reset_Tabs()
					self.changingOption = false
				end
			else
				self.onTab = false
				self.titleTxt.content = '< ' .. self.optionsTab[self.curTab] .. ' >'
				self.optionsCursor.visible = false
				self.controlsCursor.visible =
					(self.optionsTab[self.curTab] == 'Controls' and false)
				if self.camFollow.y > game.height / 2 then
					self.camFollow.y = game.height / 2
					self.hitboxup.y = -65
				end
			end
		else
			game.switchState(MainMenuState())
		end
	end

	if not self.waiting_input then
		if self.block_input then
			self.block_input = false
			return
		end

		if not self.onTab then
			if controls:pressed('ui_left') then
				self:changeTab(-1)
			elseif controls:pressed('ui_right') then
				self:changeTab(1)
			end

			if Keyboard.justPressed.ENTER then
				self.onTab = true
				self.titleTxt.content = self.optionsTab[self.curTab]
				self.curSelect = 1
				self:changeSelection(nil, self.allTabs.members[self.curTab])
				self.optionsCursor.visible = true

				if self.optionsTab[self.curTab] == 'Controls' then
					self.controlsCursor.visible = true
				end
			end
		else
			local selectedTab = self.optionsTab[self.curTab]

			if Keyboard.justPressed.ENTER then
				if selectedTab == 'Controls' then
					if not self.waiting_input then
						self.waiting_input = true
						self.blackFG.alpha = 0.5
						self.waitInputTxt.visible = true
					end
				elseif selectedTab == 'Gameplay' or
					selectedTab == 'Graphic' then
					if not self.changingOption then
						tabs[selectedTab].selectOption(self.curSelect, true)
						self:reset_Tabs()
						self.changingOption = true
					else
						tabs[selectedTab].selectOption(self.curSelect)
						self:reset_Tabs()
						self.changingOption = false
					end
				end
			end
			if controls:pressed('ui_left') then
				if self.optionsTab[self.curTab] == 'Controls' then
					self:changeBindSelection(-1)
				end
				if self.changingOption then
					if self.optionsTab[self.curTab] == 'Gameplay' or
						self.optionsTab[self.curTab] == 'Graphic' then
						tabs[selectedTab].changeSelection(-1)
						self:reset_Tabs()

						if selectedTab == 'Graphic' then
							self.bg = ClientPrefs.data.antialiasing
						end
					end
				end
				self.timerHold = 0
			end
			if controls:pressed('ui_right') then
				if self.optionsTab[self.curTab] == 'Controls' then
					self:changeBindSelection(1)
				end
				if self.changingOption then
					if self.optionsTab[self.curTab] == 'Gameplay' or
						self.optionsTab[self.curTab] == 'Graphic' then
						tabs[selectedTab].changeSelection(1)
						self:reset_Tabs()

						if selectedTab == 'Graphic' then
							self.bg = ClientPrefs.data.antialiasing
						end
					end
				end
				self.timerHold = 0
			end
			if controls:down('ui_left') or controls:down('ui_right') then
				self.timerHold = self.timerHold + dt
				if self.timerHold > 0.5 then
					self.timerHold = 0.45
					if self.changingOption then
						if self.optionsTab[self.curTab] == 'Gameplay' or
							self.optionsTab[self.curTab] == 'Graphic' then
							tabs[selectedTab].changeSelection((controls:down('ui_left')
								and -1 or 1))
							self:reset_Tabs()

							if selectedTab == 'Graphic' then
								self.bg = ClientPrefs.data.antialiasing
							end
						end
					end
				end
			end
			if not self.changingOption then
				if controls:pressed('ui_up') then
					self:changeSelection(-1, self.allTabs.members[self.curTab])
					self.timerHold = 0
				elseif controls:pressed('ui_down') then
					self:changeSelection(1, self.allTabs.members[self.curTab])
					self.timerHold = 0
				end
				if controls:down('ui_up') or controls:down('ui_down') then
					self.timerHold = self.timerHold + dt
					if self.timerHold > 0.5 then
						self.timerHold = 0.4
						self:changeSelection((controls:down('ui_up') and -1 or 1),
							self.allTabs.members[self.curTab])
					end
				end
			end
		end
	else
		if Keyboard.input and self.waiting_input then
			game.sound.play(paths.getSound('confirmMenu'))
			self.waiting_input = false
			self.blackFG.alpha = 0
			self.waitInputTxt.visible = false

			local controlsTable = tabs.Controls.getControls()
			local text = controlsTable[self.curSelect]

			local newBind = 'key:' .. Keyboard.input:lower()
			local secBind = 1
			if self.curBindSelect == 1 then
				secBind = 2
			end
			local oldBind = self.controls[text][self.curBindSelect]
			self.controls[text][self.curBindSelect] = newBind

			if self.controls[text][self.curBindSelect] ==
				self.controls[text][secBind] then
				self.controls[text][secBind] = oldBind
			end

			self:reset_Tabs()

			ClientPrefs.controls = table.clone(self.controls)
			controls = (require "lib.baton").new({
				controls = table.clone(self.controls)
			})

			self.block_input = true
		end
	end
end

function OptionsState:changeBindSelection(huh)
	huh = huh or 0

	game.sound.play(paths.getSound('scrollMenu'))
	self.curBindSelect = self.curBindSelect + huh
	if self.curBindSelect > 2 then
		self.curBindSelect = 1
	elseif self.curBindSelect < 1 then
		self.curBindSelect = 2
	end

	self.controlsCursor.x = (self.curBindSelect == 1 and game.width / 2 + 10 or
		self.curBindSelect == 2 and game.width / 2 + 260) - 5
end

function OptionsState:changeSelection(huh, tab)
	huh = huh or 0

	game.sound.play(paths.getSound('scrollMenu'))
	self.curSelect = self.curSelect + huh
	if self.curSelect > #tab.members then
		self.curSelect = 1
	elseif self.curSelect < 1 then
		self.curSelect = #tab.members
	end

	local yPos = tab.members[self.curSelect].members[1].y - 2
	self.optionsCursor.y = yPos
	if self.optionsTab[self.curTab] == 'Controls' then
		self.controlsCursor.y = yPos
	end
end

function OptionsState:changeTab(huh)
	huh = huh or 0

	game.sound.play(paths.getSound('scrollMenu'))
	self.curTab = self.curTab + huh
	if self.curTab > #self.optionsTab then
		self.curTab = 1
	elseif self.curTab < 1 then
		self.curTab = #self.optionsTab
	end

	self.titleTxt.content = '< ' .. self.optionsTab[self.curTab] .. ' >'

	local tabSelected = self.allTabs.members[self.curTab]
	local lastSelection = tabSelected.members[#tabSelected.members]
	local lastObject = lastSelection.members[1]
	if lastObject.y > game.height then
		self.tabBG:make(game.width * 0.8, lastObject.y - 50,
			{0, 0, 0})
	else
		self.tabBG:make(game.width * 0.8, game.height * 0.75,
			{0, 0, 0})
	end

	for _, idk in ipairs({self.allTabs, self.textGroup, self.spriteGroup}) do
		for _, grp in ipairs(idk.members) do
			for _, obj in ipairs(grp.members) do
				obj.visible = (grp.name == self.optionsTab[self.curTab])
				if grp.isLines then
					obj:make(2, self.tabBG.height - 24, {255, 255, 255})
				end
			end
		end
	end
end

return OptionsState
