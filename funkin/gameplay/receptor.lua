-- keep it in gameplay folder, it doesnt make sense for it to be ui
-- of course its a 2d element but not every shit is ui!!

local Receptor = ActorSprite:extend("Receptor")

Receptor.pixelAnim = { -- {static, pressed, confirm}
	{{0}, {4, 8},  {12, 16}}, {{1}, {5, 9}, {13, 17}}, {{2}, {6, 10}, {14, 18}},
	{{3}, {7, 11}, {15, 19}}
}

-- noteskip wip
function Receptor:new(x, y, column, skin)
	Receptor.super.new(self, x, y)

	self.holdTime = 0
	self.strokeTime = 0
	self.__strokeDelta = 0

	self.__shaderAnimations = {}
	self.glow = nil

	self.noteRotations = {x = 0, y = 0, z = 0}
	self.noteOffsets = {x = 0, y = 0, z = 0}
	self.lane = nil

	self.column = column
	self:setSkin(skin)
end

function Receptor:setSkin(skin)
	if skin == self.skin or not skin.receptors then return end

	local col = self.column
	self.skin, self.column = skin, nil
	Note.loadSkinData(self, skin.receptors, skin.skin, col)

	if col then self:setColumn(col) end
	self:play("static")
end

function Receptor:setColumn(column)
	if column == self.column then return end
	self.column = column

	local skin = self.skin
	if skin.receptors.disableRgb then
		self.__shaderAnimations.pressed = nil
	else
		local dataNotes, fixedColumn = skin.notes, column + 1
		local noteColor = dataNotes and dataNotes.colors
		noteColor = noteColor and noteColor[fixedColumn]

		if noteColor then
			self.__shaderAnimations.pressed = RGBShader.actorCreate(
				Color.fromString(noteColor[1]),
				Color.fromString(noteColor[2]),
				Color.fromString(noteColor[3])
			)
		end
	end

	if skin.glow then
		self.glow = Sprite()
		self.glow.offset.z, self.glow.origin.z, self.glow.__render = 0, 0, __NIL__
		Note.loadSkinData(self.glow, skin.glow, skin.skin, column)
	end
end

function Receptor:update(dt)
	if self.holdTime > 0 then
		self.holdTime = self.holdTime - dt
		if self.holdTime <= 0 then
			self.holdTime = 0
			self:play("static")
		end
	end

	if self.strokeTime ~= 0 and self.curAnim and self.curAnim.name:sub(1, 7) == "confirm" then
		self.__strokeDelta = self.__strokeDelta + dt
		 if self.__strokeDelta >= 0.13 then
			self.curFrame, self.animFinished = 1, false
			self.__strokeDelta = 0
		end

		if self.strokeTime ~= -1 then
			self.strokeTime = self.strokeTime - dt
			if self.strokeTime <= 0 then
				self.__strokeDelta, self.strokeTime = 0, 0
			end
		end
	end

	Receptor.super.update(self, dt)
end

function Receptor:updateHitbox()
	local width, height = self:getFrameDimensions()

	self.width = math.abs(self.scale.x * self.zoom.x) * width
	self.height = math.abs(self.scale.y * self.zoom.y) * height
	self.__width, self.__height = self.width, self.height

	self:centerOrigin(width, height)
	self:centerOffsets(width, height)
end

function Receptor:play(anim, force, frame, dontShader)
	local toPlay = anim .. '-note' .. self.column
	local realAnim = self.__animations[toPlay] and toPlay or anim
	Sprite.play(self, realAnim, force, frame)

	if anim == "confirm" and self.glow then
		local anim, toPlay = 'glow', 'glop-note' .. self.column
		local realAnim = self.glow.__animations[toPlay] and toPlay or anim
		Sprite.play(self.glow, realAnim, force, frame)
		self.updateHitbox(self.glow)
	end

	self:updateHitbox()
	self.__strokeDelta, self.strokeTime = 0, 0

	if not dontShader then
		self.shader = self.__shaderAnimations[anim]
	end
end

function Receptor:__render(camera)
	ActorSprite.__render(self, camera)

	local glow = self.glow
	if glow and self.curAnim and self.curAnim.name:sub(1, 7) == "confirm" then
		glow.x, glow.y, glow.z, glow.scale, glow.zoom, glow.rotation, glow.vertices, glow.__vertices, glow.fov, glow.mesh =
			self.x, self.y, self.z, self.scale, self.zoom, self.rotation, self.vertices, self.__vertices, self.fov, self.mesh

		ActorSprite.__render(glow, camera)
	end
end

return Receptor
