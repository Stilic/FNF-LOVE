---@class Options:SpriteGroup
local Options = SpriteGroup:extend("Options")

local settings = table.new(0, 3)
settings.Gameplay = require "funkin.ui.options.gameplay"
settings.Display = require "funkin.ui.options.display"
settings.Controls = require "funkin.ui.options.controls"

function Options:new(showBG, completionCallback)
	Options.super.new(self)

	self.settingsNames = {"Gameplay", "Display", "Controls"}
	if love.system.getDevice() == "Mobile" then
		table.delete(self.settingsNames, "Controls")
	end

	self.showBG = showBG
	self.completionCallback = completionCallback

	self.curTab = 1
	self.curSelect = 1
	self.onTab = false
	self.changingOption = false
	self.blockInput = false

	self.focus = 0

	self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.tabBGHeight = game.height - 125
	self.tabBG = Graphic(0, 105, game.height * 1.45, self.tabBGHeight, {0, 0, 0})
	self.tabBG:screenCenter("x")
	self.tabBG.alpha = 0.7
	self:add(self.tabBG)

	self.tabx, self.taby = self.tabBG.x, self.tabBG.y
	self.tabGroup = SpriteGroup(self.tabx, self.taby)
	self.selectedTab = nil
	self:add(self.tabGroup)

	self.optionsCursor = Graphic(0, 0, 0, 0, {1, 1, 1})
	self.optionsCursor.alpha = 0.1
	self.optionsCursor.visible = false
	self:add(self.optionsCursor)

	self.titleTabBG = Graphic(0, 20, game.height * 1.45, 65, {0, 0, 0})
	self.titleTabBG:screenCenter("x")
	self.titleTabBG.alpha = 0.7
	self:add(self.titleTabBG)

	self.titleTxt = Text(0, 30, "", paths.getFont("phantommuff.ttf", 40), {1, 1, 1}, "center", game.width)
	self:add(self.titleTxt)
end

function Options:enter(parent)
	self.parent = parent

	self.throttles = {}
	self.throttles.left = Throttle:make({controls.down, controls, "ui_left"})
	self.throttles.right = Throttle:make({controls.down, controls, "ui_right"})
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	local device = love.system.getDevice()
	if device == "Desktop" then
		Discord.changePresence({details = "In the Menus", state = "Options Menu"})
	elseif device == "Mobile" then
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
		enter.color = Color.GREEN
		local back = Button(enter.x - w, left.y, 0, 0, "escape")
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(right)

		self.buttons:add(enter)
		self.buttons:add(back)

		parent:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self:revive()
	if self.dontResetTab then
		self:resetTabs()
		self.dontResetTab = nil
	end
	self:changeTab()
	self.visible = true

	self.bg.alpha = self.showBG and 0.5 or 0
end

function Options:resetTabs()
	self.tabGroup:clear()
	self.curTab = 1

	for _, name in ipairs(self.settingsNames) do
		self.tabGroup:add(settings[name]:make(self))
	end
end

function Options:enterTab()
	self.curSelect = 1
	self.selectedTab = self.tabGroup.members[self.curTab]
	self.onTab = true

	local name = self.settingsNames[self.curTab]
	self.titleTxt.content = name

	self.optionsCursor.visible = true
	self:changeSelection()
end

function Options:exitTab()
	self.optionsCursor.visible = false

	self.selectedTab = nil
	self.onTab = false

	self:changeTab(0, true)
	game.sound.play(paths.getSound("cancelMenu"))
end

function Options:changeTab(add, dont)
	self.curTab = math.wrap(self.curTab + (add or 0), 1, #self.settingsNames + 1)

	if not dont then game.sound.play(paths.getSound("scrollMenu")) end

	local name = self.settingsNames[self.curTab]
	self.titleTxt.content = "< " .. name .. " >"

	local height = self.tabGroup.members[self.curTab].height
	self.tabBG.height = height > self.tabBGHeight and height or self.tabBGHeight

	for _, tab in ipairs(self.tabGroup.members) do
		tab.visible = tab.name == name
	end
end

function Options:changeSelection(add, dont)
	local tab = self.selectedTab
	self.curSelect = math.wrap(self.curSelect + (add or 0), 1, #tab.items + 1)
	while tab.items[self.curSelect].isTitle do
		self.curSelect = math.wrap(self.curSelect + (add and add < 0 and -1 or 1), 1, #tab.items + 1)
	end

	if not dont then game.sound.play(paths.getSound("scrollMenu")) end

	self.optionsCursor.x = self.tabBG.x
	self.optionsCursor.width = self.tabBG.width
	self.optionsCursor.height = tab.data:getSize()
end

function Options:changeOption(add, dont)
	if self.selectedTab.data:changeOption(self.curSelect, add, self) and self.applySettings then
		self.applySettings(self.settingsNames[self.curTab]:lower(),
			self.selectedTab.data.settings[self.curSelect][1])
	end
	if not dont then game.sound.play(paths.getSound("scrollMenu")) end
end

function Options:acceptOption(dont)
	if self.selectedTab.data:acceptOption(self.curSelect, self) and self.applySettings then
		self.applySettings(self.settingsNames[self.curTab]:lower(),
			self.selectedTab.data.settings[self.curSelect][1])
	end
	if not dont then game.sound.play(paths.getSound("scrollMenu")) end
end

function Options:update(dt)
	Options.super.update(self, dt)

	local shift
	if not self.blockInput then
		shift = Keyboard.pressed.SHIFT or controls:down("reset")
		if controls:pressed("accept") then
			if self.onTab then
				self:acceptOption()
			else
				self:enterTab()
			end
		elseif controls:pressed("back") then
			if self.onTab then
				self:exitTab()
			else
				return self.parent:remove(self)
			end
		end
	end

	local selecty = 0
	if self.onTab then
		if not self.blockInput then
			if self.throttles.up:check() then self:changeSelection(shift and -2 or -1) end
			if self.throttles.down:check() then self:changeSelection(shift and 2 or 1) end
		end

		selecty = self.selectedTab.data:getY(self.curSelect)
		if self.tabBG.height ~= self.tabBGHeight then
			local size = self.selectedTab.data:getSize()
			local max, bottom, top = self.tabBG.height - game.height + self.taby + size, size * 9, size * 2
			while selecty - self.focus > bottom and self.focus < max do self.focus = self.focus + size end
			while selecty - self.focus < top and self.focus > 0 do self.focus = self.focus - size end
			self.focus = math.clamp(self.focus, 0, max)
		end

		if self.selectedTab.data.update then self.selectedTab.data:update(dt, self) end
	else
		self.focus = 0
	end

	self.tabGroup.y = util.coolLerp(self.tabGroup.y, self.taby - self.focus, 12, dt)
	self.tabBG.y = self.tabGroup.y
	self.optionsCursor.y = self.tabBG.y + selecty

	if not self.blockInput then
		if self.onTab then
			self.throttles.left.step = 0.02
			self.throttles.right.step = 0.02
			if self.throttles.left:check() then self:changeOption(shift and -2 or -1) end
			if self.throttles.right:check() then self:changeOption(shift and 2 or 1) end
		else
			self.throttles.left.step = 1 / 18
			self.throttles.right.step = 1 / 18
			if self.throttles.left:check() then self:changeTab(-1) end
			if self.throttles.right:check() then self:changeTab(1) end
		end
	end
end

function Options:leave()
	game.sound.play(paths.getSound("cancelMenu"))

	if self.buttons then
		self.buttons:destroy()
		game.buttons.remove(self.buttons)
		self:remove(self.buttons)
	end
	self.buttons = nil
	self.applySettings = nil

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil

	self:kill()
	self.visible = false
	self.parent = nil

	if self.completionCallback then
		self.completionCallback()
	end
end

function Options:getWidth()
	self.width, self.height = game.width, game.height
	return self.width
end

function Options:getHeight()
	self.width, self.height = game.width, game.height
	return self.height
end

return Options
