local Receptor = Sprite:extend("Receptor")

Receptor.pixelAnim = { -- {static, pressed, confirm}
	{{0}, {4, 8},  {12, 16}}, {{1}, {5, 9}, {13, 17}}, {{2}, {6, 10}, {14, 18}},
	{{3}, {7, 11}, {15, 19}}
}

function Receptor:new(x, y, data, player)
	Receptor.super.new(self, x, y)

	self.data = data
	self.player = player

	self.holdTime = 0

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
	self.x = self.x - Note.swagWidth * 2 + Note.swagWidth * self.data + 3
	self:setScrollFactor()
	self:play("static")
end

function Receptor:update(dt)
	if self.holdTime > 0 then
		self.holdTime = self.holdTime - dt
		if self.holdTime <= 0 then
			self.holdTime = 0
			self:play("static")
		end
	end
	Receptor.super.update(self, dt)
end

function Receptor:play(anim, force, frame)
	Receptor.super.play(self, anim, force, frame)

	self:centerOffsets()
	self:centerOrigin()
end

return Receptor
