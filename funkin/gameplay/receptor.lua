-- keep it in gameplay folder, it doesnt make sense for it to be ui
-- of course its a 2d element but not every shit is ui!!

local Receptor = Sprite:extend("Receptor")

Receptor.pixelAnim = { -- {static, pressed, confirm}
	{{0}, {4, 8},  {12, 16}}, {{1}, {5, 9}, {13, 17}}, {{2}, {6, 10}, {14, 18}},
	{{3}, {7, 11}, {15, 19}}
}

-- noteskip wip
function Receptor:new(x, y, column, noteskin)
	Receptor.super.new(self, x, y)

	self.holdTime = 0
	self:setColumn(column)

	self:play("static")
end

function Receptor:setColumn(column)
	self.column = column
	local dir = Note.directions[column + 1]

	self:setFrames(paths.getSparrowAtlas("skins/normal/NOTE_assets"))
	self.scale.x, self.scale.y = 0.7, 0.7

	self:addAnimByPrefix("static", "arrow" .. dir:upper(), 24, false)
	self:addAnimByPrefix("pressed", dir .. " press", 24, false)
	self:addAnimByPrefix("confirm", dir .. " confirm", 24, false)
end

function Receptor:updateHitbox()
	local width, height = self:getFrameDimensions()

	self.width = math.abs(self.scale.x * self.zoom.x) * width
	self.height = math.abs(self.scale.y * self.zoom.y) * height
	self.__width, self.__height = self.width, self.height

	self:centerOrigin(width, height)
	self:centerOffsets(width, height)
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
	self:updateHitbox()
end

return Receptor
