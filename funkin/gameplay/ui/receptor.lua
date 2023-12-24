local Receptor = Sprite:extend("Receptor")

Receptor.pixelAnim = { -- {static, pressed, confirm}
	{ { 0 }, { 4, 8 }, { 12, 16 } }, { { 1 }, { 5, 9 }, { 13, 17 } }, { { 2 }, { 6, 10 }, { 14, 18 } },
	{ { 3 }, { 7, 11 }, { 15, 19 } }
}

function Receptor:new(x, y, data, player)
	Receptor.super.new(self, x, y)

	self.data = data
	self.player = player

	self.__timer = 0

	if PlayState.pixelStage then
		self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'))
		self.width = self.width / 4
		self.height = self.height / 5
		self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'), true,
			math.floor(self.width), math.floor(self.height))

		self.antialiasing = false
		self:setGraphicSize(math.floor(self.width * 6))

		self:addAnim('static', Receptor.pixelAnim[data + 1][1])
		self:addAnim('pressed', Receptor.pixelAnim[data + 1][2], 12, false)
		self:addAnim('confirm', Receptor.pixelAnim[data + 1][3], 24, false)
	else
		self:setFrames(paths.getSparrowAtlas("skins/normal/NOTE_assets"))
		self:setGraphicSize(math.floor(self.width * 0.7))

		local dir = Note.directions[data + 1]
		self:addAnimByPrefix("static", "arrow" .. string.upper(dir), 24, false)
		self:addAnimByPrefix("pressed", dir .. " press", 24, false)
		self:addAnimByPrefix("confirm", dir .. " confirm", 24, false)
	end

	self:updateHitbox()
end

function Receptor:groupInit()
	self.x = self.x - Note.swagWidth * 2 + Note.swagWidth * self.data
	self:setScrollFactor()
	self:play("static")
end

function Receptor:update(dt)
	if self.__timer > 0 then
		self.__timer = self.__timer - dt
		if self.__timer <= 0 then
			self.__timer = 0
			self:play("static")
		end
	end
	Receptor.super.update(self, dt)
end

function Receptor:play(anim, force)
	Receptor.super.play(self, anim, force)

	self:centerOffsets()
	self:centerOrigin()

	if not PlayState.pixelStage and anim == "confirm" then
		if self.data == 0 then
			self.offset.x, self.offset.y = self.offset.x - 1, self.offset.y - 3
		elseif self.data == 1 then
			self.offset.x, self.offset.y = self.offset.x - 2, self.offset.y - 2
		elseif self.data == 2 then
			self.offset.x, self.offset.y = self.offset.x - 1,
				self.offset.y - 0.5
		elseif self.data == 3 then
			self.offset.x = self.offset.x - 1.5
		end
	end
end

function Receptor:confirm(time)
	self:play("confirm", true)
	self.__timer = time
end

return Receptor
