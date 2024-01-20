local ModsState = State:extend("ModsState")

function ModsState:enter()
	Mods.loadMods()
	self.curSelected = table.find(Mods.mods, Mods.currentMod) or 1

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuDesat'))
	self.bg:setScrollFactor()
	self.bg:screenCenter()
	self:add(self.bg)
	if #Mods.mods > 0 then
		self.bg.color = Color.fromString(Mods.getMetadata(Mods.mods[self.curSelected]).color)
	end

	self.cardGroup = Group()
	self:add(self.cardGroup)

	self.noModsTxt = Alphabet(0, 0, 'No Mods Here', true, false)
	self.noModsTxt:screenCenter()
	self:add(self.noModsTxt)
	self.noModsTxt.visible = (#Mods.mods == 0)

	game.camera.target = {x = game.width / 2, y = game.height / 2}

	if #Mods.mods > 0 then
		for i = 1, #Mods.mods do
			local card = ModCard(-50 + (i * 580), 120, Mods.mods[i])
			card:screenCenter('y')
			self.cardGroup:add(card)
		end

		local cardMidPointX = self.cardGroup.members[self.curSelected].x + 210
		self.camFollow = {x = cardMidPointX, y = game.height / 2}
	else
		self.camFollow = {x = game.width / 2, y = game.height / 2}
	end

	local device = love.system.getDevice()
	-- Update Presence
	if device == "Desktop" then
		Discord.changePresence({details = "In the Menus", state = "Mods Menu"})
	elseif device == "Mobile" then
		self.buttons = ButtonGroup()
		self.buttons.width = 134
		self.buttons.height = 134

		local w = self.buttons.width

		local left = Button(2, game.height - w, 0, 0, "left")
		local right = Button(left.x + w, left.y, 0, 0, "right")

		local enter = Button(game.width - w, left.y, 0, 0, "return")
		enter.color = Color.GREEN
		local back = Button(enter.x - w, left.y, 0, 0, "escape")
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(right)
		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end
end

function ModsState:update(dt)
	ModsState.super.update(self, dt)

	game.camera.target.x, game.camera.target.y =
		util.coolLerp(game.camera.target.x, self.camFollow.x, 12, dt),
		util.coolLerp(game.camera.target.y, self.camFollow.y, 12, dt)

	if #Mods.mods > 0 then
		if controls:pressed('ui_left') then self:changeSelection(-1) end
		if controls:pressed('ui_right') then self:changeSelection(1) end

		if controls:pressed('accept') then self:selectMods() end
	end

	if controls:pressed('back') then
		game.switchState(MainMenuState())
	end

	if #Mods.mods > 0 then
		local colorBG = Color.fromString(Mods.getMetadata(Mods.mods[self.curSelected]).color)
		self.bg.color[1], self.bg.color[2], self.bg.color[3] =
			util.coolLerp(self.bg.color[1], colorBG[1], 3, dt),
			util.coolLerp(self.bg.color[2], colorBG[2], 3, dt),
			util.coolLerp(self.bg.color[3], colorBG[3], 3, dt)
	end
end

function ModsState:selectMods()
	local selectedMods = Mods.mods[self.curSelected]

	if selectedMods == Mods.currentMod then
		Mods.currentMod = nil
	else
		Mods.currentMod = selectedMods
	end

	game.save.data.currentMod = Mods.currentMod

	game.sound.music:stop()
	TitleState.initialized = false
	game.switchState(TitleState())
end

function ModsState:changeSelection(change)
	if change == nil then change = 0 end

	self.curSelected = self.curSelected + change

	if self.curSelected > #Mods.mods then
		self.curSelected = 1
	elseif self.curSelected < 1 then
		self.curSelected = #Mods.mods
	end

	local cardMidPointX = self.cardGroup.members[self.curSelected].x + 210
	self.camFollow = {x = cardMidPointX, y = game.height / 2}

	if #Mods.mods > 1 then
		game.sound.play(paths.getSound('scrollMenu'))
	end
end

return ModsState
