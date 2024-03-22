local PauseSubstate = Substate:extend("PauseSubstate")

function PauseSubstate:new()
	PauseSubstate.super.new(self)

	Timer.setSpeed(1)

	self.menuItems = {"Resume", "Restart Song", "Options", "Exit to menu"}
	self.curSelected = 1

	self.blockInput = false

	self:loadMusic()

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

function PauseSubstate:loadMusic()
	self.curPauseMusic = ClientPrefs.data.pauseMusic
	self.music = game.sound.load(paths.getMusic('pause/' .. self.curPauseMusic))
end

function PauseSubstate:enter()
	self.music:play(0, true)
	self.music:fade(6, 0, 0.7)

	Timer.tween(0.4, self.bg, {alpha = 0.6}, 'in-out-quart')

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134
		local gw, gh = game.width, game.height

		local down = VirtualPad("down", 0, gh - w)
		local up = VirtualPad("up", 0, down.y - w)
		local enter = VirtualPad("return", gw - w, down.y)
		enter.color = Color.GREEN

		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(enter)
		self:add(self.buttons)
	end

	self:changeSelection()
end

function PauseSubstate:update(dt)
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
			["Restart Song"] = function()
				game.resetState(true)
				if self.buttons then
					self.buttons:destroy()
				end
			end,
			["Options"] = function()
				if self.buttons then
					self.buttons:disable()
				end
				self.optionsUI = self.optionsUI or Options(false, function()
					self.blockInput = false

					if self.buttons then
						self.buttons:enable()
					end

					for _, item in ipairs(self.grpShitMenu.members) do
						item.alpha = 0.6
						if item.targetY == 0 then item.alpha = 1 end
					end
				end)
				self.optionsUI.applySettings = bind(self, self.onSettingChange)
				self.optionsUI:setScrollFactor()
				self.optionsUI:screenCenter()
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

function PauseSubstate:onSettingChange(setting, option)
	if self.parent and self.parent.onSettingChange then
		self.parent:onSettingChange(setting, option)
	end

	if setting == "gameplay" and option == "pauseMusic" then
		Timer.after(1, function()
			if not self.parent or ClientPrefs.data.pauseMusic == self.curPauseMusic then return end
			self.music:fade(0.7, self.music:getVolume(), 0)
			Timer.after(0.8, function()
				self.music:stop()
				if not self.parent then return end
				self:loadMusic()
				self.musicVolume = 0.7
				self.music:play(0, true)
			end)
		end)
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

	if self.buttons then self.buttons:destroy() end
	PauseSubstate.super.close(self)
end

return PauseSubstate
