local ModsState = State:extend("ModsState")
local ModCard = require "funkin.ui.mods.card"

function ModsState:enter(pre)
	Mods.loadMods()
	self.prevMods = nil
	self.previousState = pre
	self.switchingMods = false
	self.curColor = Color.WHITE

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuDesat'))
	self.bg:setGraphicSize(math.floor(
		self.bg.width * (game.width / self.bg.width)))
	self.bg:updateHitbox()
	self.bg:screenCenter()
	self:add(self.bg)

	self.bd = BackDrop(0, 0, game.width, game.height, 72, nil, {0, 0, 0, 0}, 26)
	self.bd:setScrollFactor()
	self.bd.alpha = 0.5
	self:add(self.bd)

	self.cards = MenuList(paths.getSound("scrollMenu"), false, "horizontal")
	self.cards.curSelected = table.find(Mods.mods, Mods.currentMod) or 1
	self.cards.changeCallback = bind(self, self.changeSelection)
	self:add(self.cards)

	if #Mods.mods == 0 then
		self.noModsTxt = AtlasText(0, 0, 'No mods here', "bold")
		self.noModsTxt:screenCenter()
		self:add(self.noModsTxt)
	end

	if #Mods.mods > 0 then
		for i = 1, #Mods.mods do
			local card = ModCard(0, 0, Mods.mods[i])
			self.cards:add(card)
			card.xAdd = (game.width - 432) / 2
			card.xMult = 400
		end
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
		enter.color = Color.LIME
		local back = VirtualPad("escape", enter.x - w, left.y, w, w)
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(right)
		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
	end

	self.bg.color = self.curColor
	self.bd.color = Color.saturate(self.bg.color, 0.4)

	if #Mods.mods > 0 then
		self.cards:changeSelection()
		self:changeSelection()
		self.cards.selectCallback = bind(self, self.selectMods)
		self.bg.color = self.curColor
		self.bd.color = Color.saturate(self.bg.color, 0.4)
	end

	ModsState.super.enter(self)
end

function ModsState:update(dt)
	ModsState.super.update(self, dt)

	for _, mod in pairs(self.cards.members) do
		local yPos = self.cards.curSelected == mod.ID and 50 or 502
		mod.y = util.coolLerp(mod.y, yPos, 12, dt)
	end

	if not self.switchingMods then
		if controls:pressed('back') then
			game.switchState(self.previousState)
		end
	end

	self.bg.color = Color.lerpDelta(self.bg.color, self.curColor, 3, dt)
	self.bd.color = Color.saturate(self.bg.color, 0.4)
end

function ModsState:selectMods(card)
	local selectedMods = Mods.mods[self.cards.curSelected]
	if selectedMods == Mods.currentMod then
		Mods.currentMod = nil

		Tween.tween(card.enableCheck.color, {[1] = 1, [2] = 0, [3] = 0}, 0.5, {ease = "circOut", onComplete = function()
			Tween.tween(game.camera, {zoom = 1.15, alpha = 0}, 1.5, {ease = "sineIn", onComplete = function()
				if game.sound.music then game.sound.music:stop() end
				Timer.wait(1, function() game.switchState(TitleState(), true) end)
			end})
		end})
	else
		Mods.currentMod = selectedMods

		Tween.tween(card.enableCheck.color, {[1] = 0, [2] = 1, [3] = 0}, 0.5, {ease = "circOut"})
		if self.prevMods then
			local prevCard = self.cards.members[self.prevMods]
			Tween.tween(prevCard.enableCheck.color, {[1] = 1, [2] = 0, [3] = 0}, 0.5, {ease = "circOut"})
		end

		Tween.tween(game.camera, {zoom = 1.05}, 0.5, {ease = "circOut", onComplete = function()
			Tween.tween(game.camera, {zoom = 1.15, alpha = 0}, 1.5, {ease = "sineIn", onComplete = function()
				if game.sound.music then game.sound.music:stop() end
				Timer.wait(1, function() game.switchState(TitleState(), true) end)
			end})
		end})
	end

	util.playSfx(paths.getSound('confirmMenu'))
	if game.sound.music then game.sound.music:fade(1.5, 1, 0) end

	game.save.data.currentMod = Mods.currentMod
	self.switchingMods = true

	TitleState.initialized = false
end

function ModsState:changeSelection(_, mod)
	if not mod then return end
	local color = Color.fromString(mod.metadata.color or "#1F1F1F")
	self.curColor = {color[1] or 1, color[2] or 1, color[3] or 1}
end

return ModsState
