local OptionsSubstate = require "funkin.substates.options"

local PauseSubstate = Substate:extend("PauseSubstate")

function PauseSubstate:new()
	PauseSubstate.super.new(self)

	self.menuItems = {"Resume", "Restart Song", "Options", "Exit to menu"}
	self.curSelected = 1

	self.music = game.sound.load(paths.getMusic('pause/' .. ClientPrefs.data.pauseMusic))

	self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
	self.bg.alpha = 0
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.grpShitMenu = Group()
	self:add(self.grpShitMenu)

	for i = 0, #self.menuItems - 1 do
		local item =
			Alphabet(0, 70 * i + 30, self.menuItems[i + 1], true, false)
		item.isMenuItem = true
		item.targetY = i
		self.grpShitMenu:add(item)
	end

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

		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(enter)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end
end

function PauseSubstate:enter()
	self.music:play(0, true)

	Timer.tween(0.4, self.bg, {alpha = 0.6}, 'in-out-quart')

	self:changeSelection()
end

function PauseSubstate:update(dt)
	if self.music:getVolume() < 0.5 then
		self.music:setVolume(self.music:getVolume() + 0.01 * dt)
	end
	PauseSubstate.super.update(self, dt)

	if controls:pressed('ui_up') then self:changeSelection(-1) end
	if controls:pressed('ui_down') then self:changeSelection(1) end

	if controls:pressed('accept') then
		local daChoice = self.menuItems[self.curSelected]

		switch(daChoice, {
			["Resume"] = function () self:close() end,
			["Restart Song"] = function () game.resetState() end,
			["Options"] = function ()
				local toSubstate = OptionsSubstate()
				toSubstate.cameras = {self.parent.camOther}
				toSubstate.applySettings = function (setting)
					self.parent:onSettingChange(setting)
				end
				self.grpShitMenu.visible = false
                if love.system.getDevice() == "Mobile" then
                    self.buttons.visible = false
                    game.buttons.remove(self.buttons)
                end
				self:openSubstate(toSubstate)
			end,
			["Exit to menu"] = function ()
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
    if love.system.getDevice() == "Mobile" then game.buttons.remove(self.buttons) end
	PauseSubstate.super.close(self)
end

return PauseSubstate
