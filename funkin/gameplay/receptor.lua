-- keep it in gameplay folder, it doesnt make sense for it to be ui
-- of course its a 2d element but not every shit is ui!!

local Receptor = ActorSprite:extend("Receptor")

Receptor.pixelAnim = { -- {static, pressed, confirm}
	{{0}, {4, 8},  {12, 16}}, {{1}, {5, 9}, {13, 17}}, {{2}, {6, 10}, {14, 18}},
	{{3}, {7, 11}, {15, 19}}
}

-- noteskip wip
function Receptor:new(x, y, column, noteskin)
	Receptor.super.new(self, x, y)

	self.scale.x, self.scale.y = 0.7, 0.7
	self.holdTime = 0
	self.strokeTime = 0
	self.__strokeDelta = 0

	self.noteRotations = {x = 0, y = 0, z = 0}
	self.noteOffsets = {x = 0, y = 0, z = 0}
	self.lane = nil

	self:setNoteskin(noteskin)
	self:setColumn(column)

	self:play("static")
end

function Receptor:setNoteskin(noteskin)
	if noteskin == self.noteskin then return end
	self.noteskin = noteskin

	local col = self.column
	self.column = nil

	self:setFrames(paths.getSparrowAtlas("skins/" .. noteskin .."/NOTE_assets"))

	if col then self:setColumn(col) end
end

function Receptor:setColumn(column)
	if column == self.column then return end
	self.column = column

	local dir = Note.directions[column + 1]
	self:addAnimByPrefix("static", "arrow" .. dir:upper(), 24, false)
	self:addAnimByPrefix("pressed", dir .. " press", 24, false)
	self:addAnimByPrefix("confirm", dir .. " confirm", 24, false)
end

function Receptor:update(dt)
	if self.holdTime > 0 then
		self.holdTime = self.holdTime - dt
		if self.holdTime <= 0 then
			self.holdTime = 0
			self:play("static")
		end
	end

	if self.strokeTime ~= 0 and self.curAnim and self.curAnim.name == "confirm" then
		self.strokeTime = self.strokeTime - dt
		if self.strokeTime <= 0 then
			self.__strokeDelta, self.strokeTime  = 0, 0
		else
			self.__strokeDelta = self.__strokeDelta + dt
		 	if self.__strokeDelta >= 0.13 then
				self.curFrame, self.animFinished = 1, false
				self.__strokeDelta = 0
			end
		end
	end

	Receptor.super.update(self, dt)
end

function Receptor:play(anim, force, frame)
	Receptor.super.play(self, anim, force, frame)
	self:centerOrigin()
	self:centerOffsets()
	self.strokeTime = 0
end

return Receptor
