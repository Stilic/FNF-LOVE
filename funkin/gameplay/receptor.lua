-- keep it in gameplay folder, it doesnt make sense for it to be ui
-- of course its a 2d element but not every shit is ui!!

local Receptor = ActorSprite:extend("Receptor")

local axes = {
	"x", "y", "z",
	"rotX", "rotY", "rotZ",
	"sizeX", "sizeY", "sizeZ", "size",
	"red", "green", "blue", "alpha",
	"skewX", "skewY", "skewZ"
}
Receptor.axes = axes

function Receptor:new(x, y, direction, skin)
	Receptor.super.new(self, x, y)

	self.holdTime = 0
	self.strokeTime = 0
	self.__strokeDelta = 0

	self.__shaderAnimations = {}
	self.__splashAnimations = {}
	self.__splashCaches = {}
	self.splashes = {}
	self.hideReceptor = false
	self.glow = nil

	self.directions = {x = 0, y = 0, z = 0}
	self.noteRotations = {x = 0, y = 0, z = 0}
	self.noteOffsets = {x = 0, y = 0, z = 0}
	self.noteSplines = {}
	self.noteAngles = 0
	self.lane = nil

	self.direction, self.data = direction, direction -- data is for backward compatibilty
	self:setSkin(skin)
end

local retOne, retPos = {sizeX = true, sizeY = true, sizeZ = true, size = true, red = true, green = true, blue = true, alpha = true}, {y = true}
function Receptor.getModValue(axis, v1, v2)
	return retOne[axis] and v1 * v2 or v1 + v2
end

function Receptor.getDefaultValue(axis, pos)
	return retOne[axis] and 1 or (retPos[axis] and pos or 0)
end

function Receptor.getDefaultValues(values)
	values = values or table.new(0, #axes)
	for _, axis in ipairs(axes) do values[axis] = Receptor.getDefaultValue(axis) end
	return values
end

function Receptor:getValue(pos, axis)
	local splineAxis = self.noteSplines[axis]
	if not splineAxis then return Receptor.getDefaultValue(axis, pos) end

	local got = 1
	for i = 2, #splineAxis - 1 do
		if pos >= splineAxis[i].position then got = i end
	end

	local spline, nextSpline = splineAxis[got], splineAxis[got + 1]

	local start, length = spline.position, nextSpline.position - spline.position
	local tween, ease, s = Timer.tween[spline.tween], spline.ease, (pos - start) / length
	local value, toValue = spline.value, nextSpline.value - spline.value
	if ease == "out" then
		return value + (1 - tween(1 - s)) * toValue
	elseif ease == "inout" then
		return value + (s < 0.5 and tween(s * 2) or 2 - tween(2 - (s * 2))) * toValue / 2
	elseif ease == "outin" then
		return value + (s < 0.5 and 1 - tween(1 - (s * 2)) or 1 + tween(s * 2 - 1)) * toValue / 2
	end
	return value + tween(s) * toValue
end

function Receptor:getValues(pos, values)
	values = values or Receptor.getDefaultValues()
	for _, axis in ipairs(axes) do values[axis] = Receptor.getModValue(axis, values[axis], self:getValue(pos, axis)) end
	return values
end

function Receptor:setSpline(axis, idx, value, position, tween, ease)
	local spline = {
		value = value or Receptor.getDefaultValue(axis, position),
		position = position or 0,
		tween = tween or "linear",
		ease = ease or "inout"
	}

	local splineAxis = self.noteSplines[axis] or table.new(idx, 0)
	for i = 1, idx - 1 do
		splineAxis[i] = splineAxis[i] or {
			value = Receptor.getDefaultValue(axis, position),
			position = 0,
			tween = "linear"
		}
	end
	self.noteSplines[axis], splineAxis[idx] = splineAxis, spline
end

function Receptor:setSkin(skin)
	if skin == self.skin or not skin.receptors then return end

	local col = self.direction
	self.skin, self.direction = skin, nil
	Note.loadSkinData(self, skin, "receptors", col)
	self.__shaderAnimations.static = self.shader

	if col then self:setDirection(col) end
	self:play("static")
end

function Receptor:setDirection(direction)
	if direction == self.direction then return end
	self.direction, self.data = direction, direction -- data is for backward compatibilty

	local skin = self.skin
	if skin.glow then
		self.glow = Sprite()
		self.glow.offset.z, self.glow.origin.z, self.glow.__render = 0, 0, __NIL__
		Note.loadSkinData(self.glow, skin, "glow", direction)
	end

	table.clear(self.__splashAnimations)
	if skin.splashes then
		for _, anim in ipairs(skin.splashes.animations) do
			if anim[1]:sub(1, 6) == "splash" then
				table.insert(self.__splashAnimations, anim[1])
			end
		end
	end
end

function Receptor:spawnSplash()
	if not self.skin or not self.skin.splashes or #self.splashes > 4 then return end

	local splash = table.remove(self.__splashCaches)
	if not splash then
		splash = ActorSprite()
		splash.__shaderAnimations, splash.ignoreAffectByGroup = {}, true
		Note.loadSkinData(splash, self.skin, "splashes", self.direction)
	end
	splash.direction, splash.parent = self.direction, self
	splash.x, splash.y, splash.z = self._x, self._y, self._z

	Receptor.play(splash, self.__splashAnimations[math.random(1, #self.__splashAnimations)], true)
	table.insert(self.splashes, splash)
	return splash
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
			local time = self.__strokeTime
			self.curFrame, self.animFinished = 1, false
			if self.glow then
				self.glow.curFrame, self.glow.animFinished = 1, false
			end
			self.__strokeDelta = 0
		end

		if self.strokeTime ~= -1 then
			self.strokeTime = self.strokeTime - dt
			if self.strokeTime <= 0 then
				self.__strokeDelta, self.strokeTime = 0, 0
			end
		end
	end

	if self.glow then
		ActorSprite.update(self.glow, dt)
	end

	ActorSprite.update(self, dt)

	for i = #self.splashes, 1, -1 do
		local splash = self.splashes[i]
		if splash.animFinished then
			table.remove(self.splashes, i)
			table.insert(self.__splashCaches, splash)
		end
	end
end

function Receptor:play(anim, force, frame, dontShader)
	local toPlay = anim .. '-note' .. self.direction
	local realAnim = self.__animations[toPlay] and toPlay or anim
	Sprite.play(self, realAnim, force, frame)

	if anim == "confirm" and self.glow then
		local anim, toPlay = 'glow', 'glop-note' .. self.direction
		local realAnim = self.glow.__animations[toPlay] and toPlay or anim
		Sprite.play(self.glow, realAnim, force, frame)
		Note.updateHitbox(self.glow)
	end

	Note.updateHitbox(self)
	self.__strokeDelta, self.strokeTime = 0, 0

	if not dontShader and self.__shaderAnimations then
		self.shader = self.__shaderAnimations[anim]
	end
end

function Receptor:destroy()
	Receptor.super.destroy(self)
	if self.glow then self.glow:destroy() end
	if self.splashes then for i, splash in ipairs(self.splashes) do
			splash:destroy(); self.splashes[i] = nil
		end end
	if self.__splashCaches then for i, splash in ipairs(self.__splashCaches) do
			splash:destroy(); self.__splashCaches[i] = nil
		end end
	self.splashes, self.__splashCaches, self.__splashAnimations = nil
end

function Receptor:__render(camera)
	self._x, self._y, self._z = self.x, self.y, self.z
	if not self.hideReceptor then
		ActorSprite.__render(self, camera)
	end

	local glow = self.glow
	if glow and glow.visible and self.curAnim and self.curAnim.name:sub(1, 7) == "confirm" then
		glow.x, glow.y, glow.z, glow.scale, glow.zoom, glow.rotation, glow.vertices, glow.__vertices, glow.fov, glow.mesh =
			self.x, self.y, self.z, self.scale, self.zoom, self.rotation, self.vertices, self.__vertices, self.fov, self.mesh

		ActorSprite.__render(glow, camera)
	end
end

return Receptor
