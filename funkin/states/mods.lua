local ModsState = State:extend("ModsState")

function ModsState:enter()
	Mods.loadMods()
	self.prevMods = nil
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

	self.bd = BackDrop(0, 0, game.width, game.height, 72, nil, {0,0,0,0}, 26)
	self.bd:setScrollFactor()
	self.bd.alpha = 0.5
	self:add(self.bd)

	local colorBG = Color.fromString(Mods.getMetadata(Mods.mods[self.curSelected]).color or "#101010")
	self.bg.color = colorBG

	local color = {Color.RGBtoHSL(colorBG[1], colorBG[2], colorBG[3])}
	color[2] = color[2] + 0.4
	colorBG = {Color.HSLtoRGB(color[1], color[2], color[3])}
	self.bd.color = colorBG

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

	self.infoTxt = Text(6, game.height * 0.96, 'Select the current mod to disable it',
		paths.getFont('phantommuff.ttf', 24))
	self.infoTxt:screenCenter('x')
	self.infoTxt:setScrollFactor()
	self.infoTxt.visible = (Mods.currentMod ~= nil)
	self:add(self.infoTxt)

	-- Update Presence
	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Mods Menu"})
	end

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local left = VirtualPad("left", 0, game.height - w)
		local right = VirtualPad("right", w, left.y)

		local enter = VirtualPad("return", game.width - w, left.y)
		enter.color = Color.GREEN
		local back = VirtualPad("escape", enter.x - w, left.y, w, w)
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(right)
		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
	end

	ModsState.super.enter(self)
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

	local colorBG = Color.fromString(Mods.getMetadata(Mods.mods[self.curSelected]).color or "#101010")
	self.bg.color[1], self.bg.color[2], self.bg.color[3] =
		util.coolLerp(self.bg.color[1], colorBG[1], 3, dt),
		util.coolLerp(self.bg.color[2], colorBG[2], 3, dt),
		util.coolLerp(self.bg.color[3], colorBG[3], 3, dt)

	local color = {Color.RGBtoHSL(colorBG[1], colorBG[2], colorBG[3])}
	color[2] = color[2] + 0.4
	colorBG = {Color.HSLtoRGB(color[1], color[2], color[3])}

	self.bd.color[1], self.bd.color[2], self.bd.color[3] =
		util.coolLerp(self.bd.color[1], colorBG[1], 3, dt),
		util.coolLerp(self.bd.color[2], colorBG[2], 3, dt),
		util.coolLerp(self.bd.color[3], colorBG[3], 3, dt)
end

function ModsState:selectMods()
	local card = self.cardGroup.members[self.curSelected]
	local selectedMods = Mods.mods[self.curSelected]
	if selectedMods == Mods.currentMod then
		Mods.currentMod = nil

		Timer.tween(0.5, card.enableCheck.color, {[1] = 1, [2] = 0, [3] = 0}, "out-circ", function()
			Timer.tween(1, game.camera, {zoom = 1.15, alpha = 0}, "in-sine", function()
				game.sound.music:stop()
				Timer.after(1, function() game.switchState(TitleState(), true) end)
			end)
		end)
	else
		Mods.currentMod = selectedMods

		Timer.tween(0.5, card.enableCheck.color, {[1] = 0, [2] = 1, [3] = 0}, "out-circ")
		if self.prevMods then
			local prevCard = self.cardGroup.members[self.prevMods]
			Timer.tween(0.5, prevCard.enableCheck.color, {[1] = 1, [2] = 0, [3] = 0}, "out-circ")
		end

		Timer.tween(0.5, game.camera, {zoom = 1.05}, "out-circ", function()
			Timer.tween(1, game.camera, {zoom = 1.15, alpha = 0}, "in-sine", function()
				game.sound.music:stop()
				Timer.after(1, function() game.switchState(TitleState(), true) end)
			end)
		end)
	end

	game.sound.play(paths.getSound('confirmMenu'))
	game.sound.music:fade(1.5, 1, 0)

	game.save.data.currentMod = Mods.currentMod
	self.switchingMods = true

	TitleState.initialized = false
end

function ModsState:changeSelection(change)
	if change == nil then change = 0 end

	self.prevMods = self.curSelected

	self.curSelected = self.curSelected + change
	self.curSelected = (self.curSelected - 1) % #Mods.mods + 1

	local cardMidPointX = self.cardGroup.members[self.curSelected].x + 210
	self.camFollow = {x = cardMidPointX, y = game.height / 2}

	if #Mods.mods > 1 then
		game.sound.play(paths.getSound('scrollMenu'))
	end
end

return ModsState
