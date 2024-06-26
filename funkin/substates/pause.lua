local PauseSubstate = Substate:extend("PauseSubstate")

function PauseSubstate:new()
	PauseSubstate.super.new(self)

	Timer.setSpeed(1)

	self.menuItems = {"Resume", "Restart Song", "Options", "Exit to menu"}
	self.curSelected = 1

	self.blockInput = false

	self:loadMusic()

	self.bg = Graphic(0, 0, game.width, game.height, Color.BLACK)
	self.bg.alpha = 0
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.grpShitMenu = Group()
	self:add(self.grpShitMenu)

	for i = 0, #self.menuItems - 1 do
		local item = Alphabet(0, 70 * i + 30, self.menuItems[i + 1], "bold", false)
		item.isMenuItem = true
		item.targetY = i
		self.grpShitMenu:add(item)
	end

	local txt, font = PlayState.SONG.song or "?", paths.getFont("vcr.ttf", 32)
	self.songText = Text(0, 15, txt, font)
	self.songText.x = game.width - self.songText:getWidth() - 28
	self.songText.alpha = 0
	self:add(self.songText)

	txt = "Difficulty: " .. (PlayState.songDifficulty or "?")
	self.diffText = Text(0, 47, txt, font)
	self.diffText.x = game.width - self.diffText:getWidth() - 28
	self.diffText.alpha = 0
	self:add(self.diffText)

	txt = GameOverSubstate.deaths .. " Blue Balls"
	self.deathsText = Text(0, 79, txt, font)
	self.deathsText.x = game.width - self.deathsText:getWidth() - 28
	self.deathsText.alpha = 0
	self:add(self.deathsText)
end

function PauseSubstate:loadMusic()
	self.curPauseMusic = self:loadPauseMusic()
	self.music = game.sound.load(paths.getMusic('pause/' .. self.curPauseMusic))
end

function PauseSubstate:enter()
	self.music:play(0, true)
	self.music:fade(6, 0, ClientPrefs.data.menuMusicVolume / 100)

	Timer.tween(0.4, self.bg, {alpha = 0.6}, 'in-out-quart')
	Timer.tween(0.4, self.songText, {y = self.songText.y + 5, alpha = 1},
		'in-out-quart')
	Timer.tween(0.4, self.diffText, {y = self.diffText.y + 5, alpha = 1},
		'in-out-quart', nil, 0.4)
	Timer.tween(0.4, self.deathsText, {y = self.deathsText.y + 5, alpha = 1},
		'in-out-quart', nil, 0.8)

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
				util.playMenuMusic()
				PlayState.chartingMode = false
				PlayState.startPos = 0
				if PlayState.storyMode then
					PlayState.seenCutscene = false
					self:close()
					self.parent:openSubstate(StickersSubstate(StoryMenuState()))
				else
					self:close()
					self.parent:openSubstate(StickersSubstate(FreeplayState()))
				end
				GameOverSubstate.deaths = 0
			end
		})
	end
end

function PauseSubstate:onSettingChange(setting, option)
	if self.parent and self.parent.onSettingChange then
		self.parent:onSettingChange(setting, option)
	end

	if setting == "gameplay" then
		if option == "pauseMusic" then
			Timer.after(1, function()
				if not self.parent or ClientPrefs.data.pauseMusic == self.curPauseMusic then return end
				self.music:fade(0.7, self.music:getVolume(), 0)
				Timer.after(0.8, function()
					self.music:stop()
					self.music:cancelFade()
					if not self.parent then return end
					self:loadMusic()
					self.music:play(ClientPrefs.data.menuMusicVolume / 100, true)
				end)
			end)
		elseif option == "menuMusicVolume" then
			self.music:fade(1, self.music:getVolume(), ClientPrefs.data.menuMusicVolume / 100)
		end
	end
end

function PauseSubstate:loadPauseMusic()
	local pauseMusic = ClientPrefs.data.pauseMusic
	if pauseMusic == "breakfast" then
		local songName = PlayState.SONG.song:lower()
		if songName == "pico" or songName == "philly nice" or songName == "blammed" then
			pauseMusic = pauseMusic .. "-pico"
		elseif songName == "senpai" or songName == "roses" or songName == "thorns" then
			pauseMusic = pauseMusic .. "-pixel"
		end
	end
	return pauseMusic
end

function PauseSubstate:changeSelection(huh)
	if huh == nil then huh = 0 end

	util.playSfx(paths.getSound('scrollMenu'))
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
	self.music:stop()
	self.music:destroy()

	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil

	if self.buttons then self.buttons:destroy() end
	PauseSubstate.super.close(self)
end

return PauseSubstate
