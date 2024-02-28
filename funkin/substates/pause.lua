local PauseSubstate = Substate:extend("PauseSubstate")

function PauseSubstate:new()
	PauseSubstate.super.new(self)

	Timer.setSpeed(1)

	self.menuItems = {"Resume", "Restart Song", "Options", "Exit to menu"}
	self.curSelected = 1

	self.blockInput = false

	self.music = game.sound.load(paths.getMusic('pause/' .. ClientPrefs.data.pauseMusic))

	self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
	self.bg.alpha = 0
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.grpShitMenu = Group()
	self:add(self.grpShitMenu)

	for i = 0, #self.menuItems - 1 do
		local item = Alphabet(0, 70 * i + 30, self.menuItems[i + 1], true, false)
		item.isMenuItem = true
		item.targetY = i
		self.grpShitMenu:add(item)
	end
end

function PauseSubstate:enter()
	self.music:play(0, true)

	Timer.tween(0.4, self.bg, {alpha = 0.6}, 'in-out-quart')

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = ButtonGroup()
		local w = 134
		local gw, gh = game.width, game.height

		local down = Button("down", 0, gh - w)
		local up = Button("up", 0, down.y - w)
		local enter = Button("return", gw - w, down.y)
		enter.color = Color.GREEN

		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(enter)
		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self:changeSelection()
end

function PauseSubstate:update(dt)
	if self.music:getVolume() < 0.5 then
		self.music:setVolume(self.music:getVolume() + 0.01 * dt)
	end
	PauseSubstate.super.update(self, dt)

	if self.blockInput then return end

	if self.throttles then
		if self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.down:check() then self:changeSelection(1) end
	end

	if controls:pressed('accept') then
		local daChoice = self.menuItems[self.curSelected]

		switch(daChoice, {
			["Resume"] = function()
				Timer.setSpeed(self.parent.playback)
				self:close()
			end,
			["Restart Song"] = function() game.resetState(true) end,
			["Options"] = function()
				local device = love.system.getDevice()
				if device == "Mobile" then
					self.buttons:set({visible = false})
					game.buttons.remove(self.buttons)
				end
				self.optionsUI = self.optionsUI or Options(false, function()
					self.blockInput = false

					if device == "Mobile" then
						self.buttons:set({visible = true})
						game.buttons.add(self.buttons)
					end

					for _, item in ipairs(self.grpShitMenu.members) do
						item.alpha = 0.6
						if item.targetY == 0 then item.alpha = 1 end
					end
				end)
				self.optionsUI.applySettings = function(setting, option)
					self.parent:onSettingChange(setting, option)
				end
				self.optionsUI:setScrollFactor()
				self.optionsUI:screenCenter()
				self.optionsUI.dontResetTab = true
				self:add(self.optionsUI)

				self.blockInput = true
				for _, item in ipairs(self.grpShitMenu.members) do
					item.alpha = 0.25
				end
			end,
			["Exit to menu"] = function()
				game.sound.music:setPitch(1)
				game.sound.playMusic(paths.getMusic("freakyMenu"))
				PlayState.chartingMode = false
				PlayState.startPos = 0
				if PlayState.storyMode then
					PlayState.seenCutscene = false
					game.switchState(StoryMenuState())
				else
					game.switchState(FreeplayState())
				end
			end
		})
	end
end

function PauseSubstate:changeSelection(huh)
	if huh == nil then huh = 0 end

	game.sound.play(paths.getSound('scrollMenu'))
	self.curSelected = self.curSelected + huh

	if self.curSelected > #self.menuItems then
		self.curSelected = 1
	elseif self.curSelected < 1 then
		self.curSelected = #self.menuItems
	end

	local bullShit = 0

	for _, item in ipairs(self.grpShitMenu.members) do
		item.targetY = bullShit - (self.curSelected - 1)
		bullShit = bullShit + 1

		item.alpha = 0.6

		if item.targetY == 0 then item.alpha = 1 end
	end
end

function PauseSubstate:close()
	self.music:kill()

	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil

	if love.system.getDevice() == "Mobile" then game.buttons.remove(self.buttons) end
	PauseSubstate.super.close(self)
end

return PauseSubstate
