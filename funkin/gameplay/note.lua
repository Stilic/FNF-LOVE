local Note = ActorSprite:extend("Note")

Note.defaultSustainSegments = 1 -- also resets on play.create

function Note.toPos(time, speed)
	return time * 450 * speed
end

local susMesh, susVerts
function Note.init()
	if susMesh then return end
	susMesh = love.graphics.newMesh(ActorSprite.vertexFormat, 16, "strip")
	susVerts = table.new(16, 0)
	for i = 1, 16 do susVerts[i] = table.new(9, 0) end
end

function Note:new(time, column, sustaintime, skin)
	Note.init()
	Note.super.new(self)
	self.ignoreAffectByGroup = true

	self.scale.x, self.scale.y = 0.7, 0.7
	self.speed = 1
	self.time = time
	self._targetTime = 0

	self.canBeHit, self.wasGoodHit, self.tooLate, self.ignoreNote = true, false, false, false
	self.priority, self.earlyHitMult, self.lateHitMult = 0, 1, 1
	self.showNote, self.showNoteOnHit = true, false
	self.hit = false
	self.type = ""
	self.group = nil

	self.sustainSegments = Note.defaultSustainSegments

	self.column, self.data = column, column -- data is for backward compatibilty
	self:setSkin(skin)
	self:setSustainTime(sustaintime)
end

function Note:clone()
	local clone = Note(self.time, self.column, self.sustainTime, self.skin)
	clone.scale.x, clone.scale.y, clone.scale.z = self.scale.x, self.scale.y, self.scale.z
	clone.zoom.x, clone.zoom.y, clone.zoom.z = self.zoom.x, self.zoom.y, self.zoom.z
	clone.rotation.x, clone.rotation.y, clone.rotation.z = self.rotation.x, self.rotation.y, self.rotation.z
	clone.canBeHit, clone.ignoreNote, clone.priority, clone.type = self.canBeHit, self.ignoreNote, self.priority, self.type
	clone.earlyHitMult, clone.lateHitMult, clone.hit = self.earlyHitMult, self.lateHitMult, self.hit
	clone.speed, clone.sustainSegments = self.speed, self.sustainSegments

	return clone
end

function Note:_addAnim(...)
	(type(select(2, ...)) == 'table' and Sprite.addAnim or Sprite.addAnimByPrefix)(self, ...)
end

function Note:loadSkinData(skinData, name, column, noRgb)
	column = column + 1

	local data = skinData[name]
	local anims, tex = data.animations, "skins/" .. skinData.skin .. "/" .. data.sprite
	if anims then
		if data.isPixel then
			self:loadTexture(paths.getImage(tex), true, data.frameWidth, data.frameHeight)
		else
			self:setFrames(paths.getSparrowAtlas(tex))
		end

		local noteDatas = not noRgb and skinData.notes
		local noteColor = noteDatas and noteDatas.colors and noteDatas.colors[column]
		for _, anim in ipairs(anims) do
			Note._addAnim(self, unpack(anim))
			if anim[5] and noteColor then
				self.__shaderAnimations[anim[1]] = RGBShader.actorCreate(
					Color.fromString(noteColor[1]),
					Color.fromString(noteColor[2]),
					Color.fromString(noteColor[3])
				)
			end
		end
	else
		self:loadTexture(paths.getImage(tex))
	end

	self.blend = data.blend or self.blend

	if data.scale ~= nil then
		self.scale.x, self.scale.y, self.scale.z = data.scale, data.scale, data.scale
	end
	if data.alpha ~= nil then self.alpha = data.alpha end
	if data.antialiasing ~= nil then self.antialiasing = data.antialiasing end

	local props = data.properties
	props = props and props[math.min(column, #props)] or props
	if props then for i, v in pairs(props) do self[i] = v end end

	if not noRgb and not data.disableRgb then
		local color = data.colors
		color = color and color[math.min(column, #color)] or color
		self.shader = color and #color >= 3 and RGBShader.actorCreate(
			Color.fromString(color[1]),
			Color.fromString(color[2]),
			Color.fromString(color[3])
		) or nil
	else
		self.shader = nil
	end
end

function Note:setSkin(skin)
	if skin == self.skin then return end
	local name, col = skin.skin, self.column
	self.skin, self.column = skin, nil

	self:loadSkinData(skin, "notes", col, true)

	if self.sustain then
		Note.loadSkinData(self.sustain, skin, "sustains", col)
		Note.loadSkinData(self.sustainEnd, skin, "sustainends", col)
	end
	if col then self:setColumn(col) end

	self:play("note")
end

function Note:setColumn(column)
	if column == self.column then return end
	self.column, self.data = column, column

	local data = self.skin.notes
	if not data.disableRgb then
		local color = data.colors[column + 1]
		self.shader = color and RGBShader.actorCreate(
			Color.fromString(color[1]),
			Color.fromString(color[2]),
			Color.fromString(color[3])
		) or nil
	else
		self.shader = nil
	end
end

function Note:setSustainTime(sustaintime)
	if sustaintime == self.sustainTime then return end
	self.sustainTime = sustaintime

	if sustaintime > 0.01 then return self:createSustain() end
	return self:destroySustain()
end

function Note:createSustain()
	if self.sustain then return end
	local sustain, susend = Sprite(), Sprite()
	self.sustain, self.sustainEnd = sustain, susend

	local skin, col = self.skin, self.column
	Note.loadSkinData(sustain, skin, "sustains", col)
	Note.loadSkinData(susend, skin, "sustainends", col)

	sustain:play("hold"); self.updateHitbox(sustain)
	susend:play("end"); self.updateHitbox(susend)

	sustain.z, sustain.offset.z, sustain.origin.z, sustain.__render = 0, 0, 0, __NIL__
	susend.z, susend.offset.z, susend.origin.z, susend.__render = 0, 0, 0, __NIL__
end

function Note:destroySustain()
	if self.sustainEnd and self.sustainEnd.destroy then self.sustainEnd:destroy() end
	if self.sustain and self.sustain.destroy then self.sustain:destroy() end
end

function Note:updateHitbox()
	local width, height = self:getFrameDimensions()

	self.width = math.abs(self.scale.x * self.zoom.x) * width
	self.height = math.abs(self.scale.y * self.zoom.y) * height
	self.__width, self.__height = self.width, self.height

	self:centerOrigin(width, height)
	self:centerOffsets(width, height)
end

function Note:destroy()
	Note.super.destroy(self)
	self:destroySustain()
end

function Note:play(anim, force, frame)
	Note.super.play(self, anim, force, frame)
	Note.updateHitbox(self)
end

function Note:_canDraw()
	if self.sustain then
		self.sustain.cameras = self.cameras
		self.sustainEnd.cameras = self.cameras
	end
	return (self.texture ~= nil and (self.width ~= 0 or self.height ~= 0)) and
		(Note.super._canDraw(self) or (
			self.sustain and (self.sustain:_canDraw() or self.sustainEnd:_canDraw())
		))
end

local values, worldSpin, toScreen = {}, Actor.worldSpin, Actor.toScreen

local function getValues(r, pos, values)
	if r then r:getValues(pos, values) end
end

local function applyMod(mods, beat, pos, notefield, column)
	for _, mod in ipairs(mods) do if mod.applyPath then mod:applyPath(values, beat, pos, notefield, column) end end
end

function Note:__render(camera)
	local grp, px, py, pz, pa, pal, rot, sc = self.group, self.x, self.y, self.z, self.angle, self.alpha, self.rotation, self.scale
	local col, time, target, speed, psx, psy, psz, prx, pry, prz = self.column, self.time, self._targetTime, self.speed,
		sc.x, sc.y, sc.z, rot.x, rot.y, rot.z

	local par, nx, ny, nz, pos, rec, beat, mods = self.parent, px, py, pz, Note.toPos(time - target, speed)
	Receptor.getDefaultValues(values)

	if par then
		beat, mods = par.beat or 0, par.modifiers
		applyMod(mods, beat, pos, par, col)
	end

	local gx, gy, gz, gsx, gsy, gsz, grx, gry, grz, gox, goy, goz = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	if grp then
		gx, gy, gz, gsx, gsy, gsz, grx, gry, grz, gox, goy, goz, rec = grp.x, grp.y, grp.z, grp.scale.x, grp.scale.y, grp.scale.z,
			grp.rotation.x, grp.rotation.y, grp.rotation.z, grp.origin.x, grp.origin.y, grp.origin.z, grp.receptor

		self.angle, rot.x, rot.y, rot.z, sc.x, sc.y, sc.z = pa + grp.memberAngles,
			prx + grp.memberRotations.x, pry + grp.memberRotations.y, prz + grp.memberRotations.z,
			psx * grp.memberScales.x, psy * grp.memberScales.y, psz * grp.memberScales.z

		if grp.affectAngle then self.angle, rot.y, rot.y, rot.z = self.angle + grp.angle, rot.y + grx, rot.y + gry, rot.z + grz end
		if grp.affectScale then sc.x, sc.y, sc.z = sc.x * gsx, sc.y * gsy, sc.z * gsz end
		if rec then
			nx, ny, nz = nx + rec.x + rec.noteOffsets.x, ny + rec.y + rec.noteOffsets.y, nz + rec.z + rec.noteOffsets.z
			rot.x, rot.y, rot.z = rot.x + rec.noteRotations.x, rot.y + rec.noteRotations.y, rot.z + rec.noteRotations.z
			grx, gry, grz = grx + rec.directions.x, gry + rec.directions.y, grz + rec.directions.z
			self.angle = self.angle + rec.noteAngles
		end

		getValues(rec, pos, values)
		local vx, vy, vz = worldSpin(
			(nx + values.x) * gsx,
			(ny + values.y) * gsy,
			(nz + values.z) * gsz,
			grx, gry, grz, gox, goy, goz)

		self.x, self.y, self.z = vx + gx, vy + gy, vz + gz
	else
		self.x, self.y, self.z = nx, ny + pos, nz
	end

	local v = values.size
	rot.x, rot.y, rot.z = rot.x + values.rotX, rot.y + values.rotY, rot.z + values.rotZ
	sc.x, sc.y, sc.z = sc.x * values.sizeX * v, sc.y * values.sizeY * v, sc.z * values.sizeZ * v
	self.alpha = pal * values.alpha

	--[[
		I'm aware that if the texture size height or scale are too small, it'll be huge draw calls
		i can't wrap it around it either since it requires a shader which would not be a big deal but
		ActorSprite and rgb uses a shader, and i have to make it around before those renders,
		I could make a canvas but who knows...

		get fucked™

		Also probably need a rework like the actorsprite
	--]]

	local sus = self.sustain
	if sus then
		local dshader, shader, r, g, b, a = ActorSprite.defaultShader, love.graphics.getShader(), love.graphics.getColor()
		local blendMode, alphaMode = love.graphics.getBlendMode()

		local fov, drawSize, drawSizeOffset = self.fov, grp and grp.drawSize or 800, grp and grp.drawSizeOffset or 0
		local suspos, minbound, maxbound = Note.toPos(time + self.sustainTime - target, speed),
			self.pressed and 0 or self.lastPress and Note.toPos(self.lastPress - target, speed) or math.max(pos, -drawSize / 2 + drawSizeOffset - ny),
			drawSize / 2 + drawSizeOffset - ny

		local segments = self.sustainSegments
		local vertLens = math.min(2 + segments * 2, 16)

		if vertLens > 2 then
			local susend, gotVerts = self.sustainEnd
			if susend and suspos >= minbound and suspos < maxbound then
				local snx, sny, snz, ssc, tex = susend.x + nx, susend.y + ny, (susend.z or 0) + nz, susend.scale, susend.texture
				local f, tw, th = susend:getCurrentFrame(), tex:getWidth(), tex:getHeight()
				local hfw, fh, uvx, uvy, uvxw, uvh = tw, th, 0, 0, 1, 1
				if f then
					uvx, uvy, hfw, fh = f.quad:getViewport()
					if susend.antialiasing then uvy, fh = uvy + 1, fh - 1 end
					uvx, uvy, uvxw, uvh = uvx / tw, uvy / th, (hfw + uvx) / tw, fh / th
				end
				local fhs = uvh / segments
				hfw, fh, gotVerts = hfw * ssc.x / 2, fh / segments * ssc.y, vertLens

				tex:setFilter(susend.antialiasing and "linear" or "nearest")
				love.graphics.setShader(susend.shader or defaultShader); love.graphics.setBlendMode(susend.blend)
				love.graphics.setColor(susend.color[1], susend.color[2], susend.color[3], susend.alpha)
				susMesh:setTexture(tex)

				getValues(rec, suspos + 1, Receptor.getDefaultValues(values)); applyMod(mods, beat, suspos + 1, par, col)
				vx, vy, vz = worldSpin(
					(snx + values.x) * gsx,
					(sny + values.y) * gsy,
					(snz + values.z) * gsz,
					grx, gry, grz, gox, goy, goz
				)
				local pvx, pvy = toScreen(vx + gx, vy + gy, vz + gz, fov)
				local enduv, vert, aa, as, ac
				for vi = 1, vertLens, 2 do
					getValues(rec, suspos, Receptor.getDefaultValues(values)); applyMod(mods, beat, suspos, par, col)
					vx, vy, vz = worldSpin(
						(snx + values.x) * gsx,
						(sny + values.y) * gsy,
						(snz + values.z) * gsz,
						grx, gry, grz, gox, goy, goz
					)

					vert, vx, vy, vz = susVerts[vi], toScreen(vx + gx, vy + gy, vz + gz, fov)

					aa = -math.atan((pvx - vx) / (pvy - vy))
					as, ac, pvx, pvy = math.fastsin(aa) * vz, math.fastcos(aa) * vz, vx, vy

					vi, vert[1], vert[2], vert[3], vert[4], vert[5], vert[6], vert[7], vert[8], vert[9] = vi + 1,
						vx - hfw * ac, vy - hfw * as, uvx * vz, (uvy + uvh) * vz, vz, 1, 1, 1, values.alpha

					vert = susVerts[vi]
					vert[1], vert[2], vert[3], vert[4], vert[5], vert[6], vert[7], vert[8], vert[9] =
						vx + hfw * ac, vy + hfw * as, uvxw * vz, (uvy + uvh) * vz, vz, 1, 1, 1, values.alpha

					if vi < vertLens then suspos, uvh = suspos - fh, uvh - fhs end
					if enduv then
						gotVerts = vi
						break
					elseif suspos < minbound then
						suspos, uvh, enduv = minbound, uvh - ((suspos - minbound) / ssc.y / th / segments), true
					end
				end

				susMesh:setDrawRange(1, gotVerts); susMesh:setVertices(susVerts); love.graphics.draw(susMesh)
			end

			if suspos >= minbound then
				local snx, sny, snz, ssc, tex = sus.x + nx, sus.y + ny, (sus.z or 0) + nz, sus.scale, sus.texture
				local f, tw, th = sus:getCurrentFrame(), tex:getWidth(), tex:getHeight()
				local hfw, fh, uvx, uvy, uvxw, uvh = tw, th, 0, 0, 1, 1
				if f then
					uvx, uvy, hfw, fh = f.quad:getViewport()
					if sus.antialiasing then uvy, fh = uvy + 1, fh - 2 end
					uvx, uvy, uvxw, uvh = uvx / tw, uvy / th, (hfw + uvx) / tw, fh / th
				end
				local ssy = math.max(fh * ssc.y, 64) / fh
				hfw, fh = hfw * ssc.x / 2, math.max(fh * ssc.y, 64)
				segments = segments * math.max(math.round(fh / 128), 1)
				fh = fh / segments

				tex:setFilter(sus.antialiasing and "linear" or "nearest")
				love.graphics.setShader(sus.shader or defaultShader); love.graphics.setBlendMode(sus.blend)
				love.graphics.setColor(sus.color[1], sus.color[2], sus.color[3], sus.alpha)
				susMesh:setTexture(tex)

				getValues(rec, suspos + 1, Receptor.getDefaultValues(values)); applyMod(mods, beat, suspos + 1, par, col)
				suspos, vertLens, vx, vy, vz = math.min(suspos, maxbound), math.min(2 + segments * 2, 16), worldSpin(
					(snx + values.x) * gsx,
					(sny + values.y) * gsy,
					(snz + values.z) * gsz,
					grx, gry, grz, gox, goy, goz
				)
				local pvx, pvy = toScreen(vx + gx, vy + gy, vz + gz, fov)
				local uvfh, fhs, uvyh, vi, enduv, vert, aa, as, ac = uvh, uvh / segments, uvy + uvh, 1
				if gotVerts then
					vert, vi, suspos, uvfh = susVerts[gotVerts], 3, suspos - fh, uvfh - fhs
					susVerts[2][1], susVerts[2][2], susVerts[2][3], susVerts[2][4], susVerts[2][5],
					susVerts[2][6], susVerts[2][7], susVerts[2][8], susVerts[2][9] =
						vert[1], vert[2], uvxw * vert[5], uvyh * vert[5], vert[5], vert[6], vert[7], vert[8], vert[9]

					vert = susVerts[gotVerts - 1]
					susVerts[1][1], susVerts[1][2], susVerts[1][3], susVerts[1][4], susVerts[1][5],
					susVerts[1][6], susVerts[1][7], susVerts[1][8], susVerts[1][9] =
						vert[1], vert[2], uvx * vert[5], uvyh * vert[5], vert[5], vert[6], vert[7], vert[8], vert[9]

					if suspos < minbound then
						suspos, uvfh, enduv = minbound, uvfh - ((suspos - minbound) / ssy / th / segments), true
					end
				end

				while true do
					getValues(rec, suspos, Receptor.getDefaultValues(values)); applyMod(mods, beat, suspos, par, col)
					vx, vy, vz = worldSpin(
						(snx + values.x) * gsx,
						(sny + values.y) * gsy,
						(snz + values.z) * gsz,
						grx, gry, grz, gox, goy, goz
					)

					vert, vx, vy, vz = susVerts[vi], toScreen(vx + gx, vy + gy, vz + gz, fov)

					aa = -math.atan((pvx - vx) / (pvy - vy))
					as, ac, pvx, pvy = math.fastsin(aa) * vz, math.fastcos(aa) * vz, vx, vy

					vi, vert[1], vert[2], vert[3], vert[4], vert[5], vert[6], vert[7], vert[8], vert[9] = vi + 1,
						vx - hfw * ac, vy - hfw * as, uvx * vz, (uvy + uvfh) * vz, vz, 1, 1, 1, values.alpha

					vert = susVerts[vi]
					vi, vert[1], vert[2], vert[3], vert[4], vert[5], vert[6], vert[7], vert[8], vert[9] = vi + 1,
						vx + hfw * ac, vy + hfw * as, uvxw * vz, (uvy + uvfh) * vz, vz, 1, 1, 1, values.alpha

					suspos, uvfh = suspos - fh, uvfh - fhs
					if enduv or vi > vertLens then
						susMesh:setDrawRange(1, vi - 1); susMesh:setVertices(susVerts); love.graphics.draw(susMesh)

						if enduv then
							break
						else
							susVerts[2][1], susVerts[2][2], susVerts[2][3], susVerts[2][4], susVerts[2][5],
							susVerts[2][6], susVerts[2][7], susVerts[2][8], susVerts[2][9] =
								vert[1], vert[2], vert[3], uvyh * vert[5], vert[5], vert[6], vert[7], vert[8], vert[9]

							vert, uvfh, vi = susVerts[vi - 2], uvh - fhs, 3
							susVerts[1][1], susVerts[1][2], susVerts[1][3], susVerts[1][4], susVerts[1][5],
							susVerts[1][6], susVerts[1][7], susVerts[1][8], susVerts[1][9] =
								vert[1], vert[2], vert[3], uvyh * vert[5], vert[5], vert[6], vert[7], vert[8], vert[9]
						end
					end

					if suspos < minbound then
						suspos, uvfh, enduv = minbound, uvfh - ((suspos - minbound) / ssy / th / segments), true
					end
				end
			end
		end

		love.graphics.setShader(shader); love.graphics.setColor(r, g, b, a)
		love.graphics.setBlendMode(blendMode, alphaMode)
	end

	if self.showNote and (not self.hit or self.showNoteOnHit) then
		ActorSprite.__render(self, camera)
	end

	self.x, self.y, self.z, self.angle, self.alpha, sc.x, sc.y, sc.z, rot.x, rot.y, rot.z = px, py, pz, pa, pal, psx, psy, psz, prx, pry, prz
end

return Note
