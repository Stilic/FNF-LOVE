local ModsState = State:extend("ModsState")

function ModsState:enter()
	Mods.loadMods()
	self.curSelected = table.find(Mods.mods, Mods.currentMod) or 1
	self.switchingMods = false

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuDesat'))
	self.bg:setScrollFactor()
	self.bg:screenCenter()
	self.bg:setGraphicSize(math.floor(self.bg.width * (game.width / self.bg.width)))
	self.bg:updateHitbox()
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
			local card = ModCard(-50 + (i * 580), 50, Mods.mods[i])
			card.ID = i
			self.cardGroup:add(card)
		end

		local cardMidPointX = self.cardGroup.members[self.curSelected].x + 210
		self.camFollow = {x = cardMidPointX, y = game.height / 2}
	else
		self.camFollow = {x = game.width / 2, y = game.height / 2}
	end

	self.infoTxt = Text(6, game.height * 0.96, 'Select the current Mod to disable',
		paths.getFont('phantommuff.ttf', 24))
	self.infoTxt:screenCenter('x')
	self.infoTxt:setScrollFactor()
	self.infoTxt.visible = (Mods.currentMod ~= nil)
	self:add(self.infoTxt)

	local device = love.system.getDevice()
	-- Update Presence
	if device == "Desktop" then
		Discord.changePresence({details = "In the Menus", state = "Mods Menu"})
	elseif device == "Mobile" then
		self.buttons = ButtonGroup()
		local w = 134

		local left = Button("left", 0, game.height - w)
		local right = Button("right", w, left.y)

		local enter = Button("return", game.width - w, left.y)
		enter.color = Color.GREEN
		local back = Button("escape", enter.x - w, left.y, w, w)
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

	for _, mod in pairs(self.cardGroup.members) do
		local yPos = self.curSelected == mod.ID and 50 or 502
		mod.y = util.coolLerp(mod.y, yPos, 12, dt)
	end

	if not self.switchingMods then
		if #Mods.mods > 0 then
			if controls:pressed('ui_left') then self:changeSelection(-1) end
			if controls:pressed('ui_right') then self:changeSelection(1) end

			if controls:pressed('accept') then self:selectMods() end
		end

		if controls:pressed('back') then
			game.switchState(MainMenuState())
		end
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

	game.sound.play(paths.getSound('confirmMenu'))

	game.save.data.currentMod = Mods.currentMod
	self.switchingMods = true

	TitleState.initialized = false
	game.sound.music:fade(1, 1, 0)
	Timer.tween(1, game.camera, {zoom = 1.1, alpha = 0}, "in-sine", function()
		game.sound.music:stop()
		Timer.after(1, function() game.switchState(TitleState(), true) end)
	end)
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
