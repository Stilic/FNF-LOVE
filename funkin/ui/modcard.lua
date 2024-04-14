local ModCard = SpriteGroup:extend("ModCard")

function ModCard:new(x, y, mods)
	ModCard.super.new(self, x, y)

	local metadata = Mods.getMetadata(mods)

	self.bg = Graphic(0, 0, 420, 620, Color.BLACK)
	self.bg.alpha = 0.5
	self.bg.config.round = {8, 8}
	self:add(self.bg)

	self.banner = Sprite(4, 4):loadTexture(Mods.getBanner(mods))
	self.banner:setGraphicSize(412)
	self.banner:updateHitbox()
	self:add(self.banner)

	self.titleBG = Graphic(4, 134, 412, 80, Color.BLACK)
	self.titleBG.alpha = 0.3
	self.titleBG.config.round = {8, 8}
	self:add(self.titleBG)

	self.titleTxt = Text(6, 136, metadata.name, paths.getFont("phantommuff.ttf", 30),
		Color.WHITE, "center", 410)
	self:add(self.titleTxt)

	self.descBG = Graphic(4, 218, 412, 340, Color.BLACK)
	self.descBG.alpha = 0.5
	self.descBG.config.round = {8, 8}
	self:add(self.descBG)

	self.descTxt = Text(14, 224, metadata.description, love.graphics.newFont(13),
		Color.WHITE, "left", 392)
	self:add(self.descTxt)

	local enabledColor = (Mods.currentMod == mods and Color.GREEN or Color.RED)
	self.enableCheck = Graphic(4, 562, 15, 54, enabledColor)
	self.enableCheck.config.round = {6, 6}
	self:add(self.enableCheck)
end

return ModCard
