local Note = ActorSprite:extend("Note")

Note.colors = {"purple", "blue", "green", "red"}
Note.directions = {"left", "down", "up", "right"}
Note.pixelAnim = {{{4}, {0}}, {{5}, {1}}, {{6}, {2}}, {{7}, {3}}}

function Note.toPos(time, speed)
	return time * 450 * speed
end

function Note:new(time, column, sustaintime, skin)
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

	self.sustainSegments = 0

	self.column = column
	self:setSkin(skin)
	self:setSustainTime(sustaintime)
end

function Note:_addAnim(...)
	(type(select(2, ...)) == 'table' and Sprite.addAnim or Sprite.addAnimByPrefix)(self, ...)
end

function Note:loadSkinData(skinData, name, column, noRgb)
	local data, fixedColumn = skinData[name], column and column + 1 or -1
	local anims, tex = data.animations, "skins/" .. skinData.skin .. "/" .. data.sprite
	if anims then
		if data.isPixel then
			self:loadTexture(paths.getImage(tex), true, data.frameWidth, data.frameHeight)
		else
			self:setFrames(paths.getSparrowAtlas(tex))
		end

		local noteDatas = not noRgb and skinData.notes
		local noteColor = noteDatas and noteDatas.colors and noteDatas.colors[fixedColumn]
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

	local scale = data.scale
	self.scale.x, self.scale.y, self.scale.z, self.antialiasing = scale, scale, scale, data.antialiasing
	if self.antialiasing == nil then self.antialiasing = true end

	local props = data.properties
	props = props and props[math.min(fixedColumn, #props)] or props
	if props then for i, v in pairs(props) do self[i] = v end end

	if not noRgb and not data.disableRgb then
		local color = data.colors
		color = color and color[math.min(fixedColumn, #color)] or color
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
	self.column = column
	
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
	self:updateHitbox()
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

local function getValue(receptor, pos, axis)
	if receptor then return receptor:getValue(pos, axis) end
end

local worldSpin, x, y, z, rotX, rotY, rotZ, sizeX, sizeY, sizeZ, size, alpha, skewX, skewY, skewZ = Actor.worldSpin,
	"x", "y", "z", "rotX", "rotY", "rotZ", "sizeX", "sizeY", "sizeZ", "size", "alpha", "skewX", "skewY", "skewZ"

function Note:__render(camera)
	local grp, px, py, pz, pa, pal, rot, sc = self.group, self.x, self.y, self.z, self.angle, self.alpha, self.rotation, self.scale
	local time, target, speed, psx, psy, psz, prx, pry, prz = self.time, self._targetTime, self.speed,
		sc.x, sc.y, sc.z, rot.x, rot.y, rot.z

	local pos, rec = Note.toPos(time - target, speed)
	local gx, gy, gz, gsx, gsy, gsz, grx, gry, grz, gox, goy, goz = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	if grp then
		gx, gy, gz, gsx, gsy, gsz, grx, gry, grz, gox, goy, goz, rec = grp.x, grp.y, grp.z, grp.scale.x, grp.scale.y, grp.scale.z,
			grp.rotation.x, grp.rotation.y, grp.rotation.z, grp.origin.x, grp.origin.y, grp.origin.z, grp.receptor

		self.angle, rot.x, rot.y, rot.z, sc.x, sc.y, sc.z = pa + grp.memberAngles,
			prx + grp.memberRotations.x, pry + grp.memberRotations.y, prz + grp.memberRotations.z,
			psx * grp.memberScales.x, psy * grp.memberScales.y, psz * grp.memberScales.z

		if grp.affectAngle then self.angle, rot.y, rot.y, rot.z = self.angle + grp.angle, rot.y + grx, rot.y + gry, rot.z + grz end
		if grp.affectScale then sc.x, sc.y, sc.z = sc.x * gsx, sc.y * gsy, sc.z * gsz end

		local vx, vy, vz = worldSpin(
			(px + (getValue(rec, pos, x) or 0)) * gsx,
			(py + (getValue(rec, pos, y) or pos)) * gsy,
			(pz + (getValue(rec, pos, z) or 0)) * gsz,
			grx, gry, grz, gox, goy, goz)

		self.x, self.y, self.z = vx + gx, vy + gy, vz + gz
	else
		self.x, self.y, self.z = px, py + pos, pz
	end

	local v = getValue(rec, pos, size) or 1
	rot.x, rot.y, rot.z = rot.x + (getValue(rec, pos, rotX) or 0), rot.y + (getValue(rec, pos, rotY) or 0), rot.z + (getValue(rec, pos, rotZ) or 0)
	sc.x, sc.y, sc.z = sc.x * (getValue(rec, pos, sizeX) or 1) * v, sc.y * (getValue(rec, pos, sizeY) or 1) * v, sc.z * (getValue(rec, pos, sizeZ) or 1) * v
	self.alpha = self.alpha * (getValue(rec, pos, alpha) or 1)

	--[[
		I'm aware that if the texture size height or scale are minimized, it'll be huge draw calls
		i can't wrap it around it either since it requires a shader which would not be a big deal but
		ActorSprite and rgb uses a shader, and i have to make it around before those renders,
		I could make a canvas but who knows...

		get fucked™
	--]]
	local sustain = self.sustain
	if sustain then
		local r, g, b, a = love.graphics.getColor()
		local shader = love.graphics.getShader()
		local blendMode, alphaMode = love.graphics.getBlendMode()
		local min, mag, anisotropy = self.texture:getFilter()
		local fov, mesh, verts, defaultShader = self.fov, self.mesh, self.__vertices, ActorSprite.defaultShader
		local drawSize, drawSizeOffset, sx, sy, sz = grp and grp.drawSize or 800, grp and grp.drawSizeOffset or 0, sc.x, sc.y, sc.z

		local susend, dont = self.sustainEnd, false
		local height = Note.toPos(self.sustainTime, speed)

		-- Sustains
		local mode = sustain.antialiasing and "linear" or "nearest"
		local susx, susy, susz = px + sustain.x - sustain.offset.x, pos + py + sustain.y - sustain.offset.y, pz + sustain.z - sustain.offset.z
		local vertsLength, vx, vy, vz = 2 + self.sustainSegments * 2

		if vertsLength > 2 then
			local f, tw, th = sustain:getCurrentFrame(), sustain.texture:getWidth(), sustain.texture:getHeight()
			local fw, fh, uvx, uvy, uvw, uvh = tw, th, 0, 0, 1, 1
			if f then
				uvx, uvy, fw, fh = f.quad:getViewport()
				uvx, uvy, uvw, uvh = uvx / tw, uvy / th, fw / tw, fh / th
				susx, susy = susx - f.offset.x, susy - f.offset.y
			end
			fw, fh = fw * sx, math.clamp(fh * sy, 64, 128) / self.sustainSegments

			sustain.texture:setFilter(mode, mode, anisotropy)
			love.graphics.setShader(sustain.shader or defaultShader); love.graphics.setBlendMode(sustain.blend)
			love.graphics.setColor(sustain.color[1], sustain.color[2], sustain.color[3], sustain.alpha)
			mesh:setTexture(sustain.texture)
			mesh:setDrawRange(1, 4)

			local uvxw, hfw, vi = uvx + uvw, fw / 2, 0
			while height > 0 do
				vi, vx, vy, vz = vi + 1, worldSpin(susx * gsx, susy * gsy, susz * gsz, grx, gry, grz, gox, goy, goz)

				height, susy = height - fh, susy + fh
				dont = susy > drawSize / 2 + drawSizeOffset - py1
				if dont then break end

				if v1 >= vertsLength then
					mesh:setVertices(verts); love.graphics.draw(mesh)

					vi = vi - 1
					verts[1][1], verts[1][2], verts[1][3], verts[1][4], verts[1][5] =
						verts[vi][1], verts[vi][2], uvx * verts[vi][5], uvy * verts[vi][5], verts[vi][5]

					vi = vi + 1
					verts[2][1], verts[2][2], verts[2][3], verts[2][4], verts[2][5] =
						verts[vi][1], verts[vi][2], uvxw * verts[vi][5], uvy * verts[vi][5], verts[vi][5]
				end

				--[[
				vx, vy, vz = worldSpin((px - hfw) * gsx, y1 * gsy, pz * gsz, grx, gry, grz, gox, goy, goz)
				verts[1][1], verts[1][2], vz = self.toScreen(vx + gx, vy + gy, vz + gz, fov)
				verts[1][3], verts[1][4], verts[1][5] = uvx * vz, uvy * vz, vz

				vx, vy, vz = worldSpin((px + hfw) * gsx, y1 * gsy, pz * gsz, grx, gry, grz, gox, goy, goz)
				verts[2][1], verts[2][2], vz = self.toScreen(vx + gx, vy + gy, vz + gz, fov)
				verts[2][3], verts[2][4], verts[2][5] = uvxw * vz, uvy * vz, vz

				vx, vy, vz = worldSpin((px + hfw) * gsx, y2 * gsy, pz * gsz, grx, gry, grz, gox, goy, goz)
				verts[3][1], verts[3][2], vz = self.toScreen(vx + gx, vy + gy, vz + gz, fov)
				verts[3][3], verts[3][4], verts[3][5] = uvxw * vz, uvyh * vz, vz

				vx, vy, vz = worldSpin((px - hfw) * gsx, y2 * gsy, pz * gsz, grx, gry, grz, gox, goy, goz)
				verts[4][1], verts[4][2], vz = self.toScreen(vx + gx, vy + gy, vz + gz, fov)
				verts[4][3], verts[4][4], verts[4][5] = uvx * vz, uvyh * vz, vz]]

				mesh:setVertices(verts)
				love.graphics.draw(mesh, 0, 0)
			end
		end

		-- Sus END
		if not dont then

		end

		love.graphics.setColor(r, g, b, a)
		love.graphics.setBlendMode(blendMode, alphaMode)
		love.graphics.setShader(shader)
	end

	if self.showNote and (not self.hit or self.showNoteOnHit) then
		ActorSprite.__render(self, camera)
	end

	self.x, self.y, self.z, self.angle, self.alpha, sc.x, sc.y, sc.z, rot.x, rot.y, rot.z = px, py, pz, pa, pal, psx, psy, psz, prx, pry, prz
end

--[[
Note.chartingMode = false

function Note:new(time, data, prevNote, sustain, parentNote)
	Note.super.new(self, 0, -2000)

	self.time = time
	self.data = data
	self.prevNote = prevNote
	if sustain == nil then sustain = false end
	self.isSustain, self.isSustainEnd, self.parentNote = sustain, false, parentNote
	self.mustPress = false
	self.canBeHit, self.wasGoodHit, self.tooLate = false, false, false
	self.earlyHitMult, self.lateHitMult = 1, 1
	self.type = ''
	self.ignoreNote = false

	self.scrollOffset = {x = 0, y = 0}

	local color = Note.colors[data + 1]
	if PlayState.pixelStage then
		if sustain then
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assetsENDS'))
			self.width = self.width / 4
			self.height = self.height / 2
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assetsENDS'),
				true, math.floor(self.width),
				math.floor(self.height))

			self:addAnim(color .. 'holdend', Note.pixelAnim[data + 1][1])
			self:addAnim(color .. 'hold', Note.pixelAnim[data + 1][2])
		else
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'))
			self.width = self.width / 4
			self.height = self.height / 5
			self:loadTexture(paths.getImage('skins/pixel/NOTE_assets'), true,
				math.floor(self.width), math.floor(self.height))

			self:addAnim(color .. 'Scroll', Note.pixelAnim[data + 1][1])
		end

		self:setGraphicSize(math.floor(self.width * 6))
		self.antialiasing = false
	else
		self:setFrames(paths.getSparrowAtlas("skins/normal/NOTE_assets"))

		if sustain then
			if data == 0 then
				self:addAnimByPrefix(color .. "holdend", "pruple end hold")
			else
				self:addAnimByPrefix(color .. "holdend", color .. " hold end")
			end
			self:addAnimByPrefix(color .. "hold", color .. " hold piece")
		else
			self:addAnimByPrefix(color .. "Scroll", color .. "0")
		end

		self:setGraphicSize(math.floor(self.width * 0.7))
	end
	self:updateHitbox()

	self:play(color .. "Scroll")

	if sustain and prevNote then
		table.insert(parentNote.children, self)

		self.alpha = 0.6
		self.earlyHitMult = 0.5
		self.scrollOffset.x = self.scrollOffset.x + self.width / 2

		self:play(color .. "holdend")
		self.isSustainEnd = true

		self:updateHitbox()

		self.scrollOffset.x = self.scrollOffset.x - self.width / 2

		if PlayState.pixelStage then
			self.scrollOffset.x = self.scrollOffset.x + 30
		end

		if prevNote.isSustain then
			prevNote:play(Note.colors[prevNote.data + 1] .. "hold")
			prevNote.isSustainEnd = false

			prevNote.scale.y = (prevNote.width / prevNote:getFrameWidth()) *
				((PlayState.conductor.stepCrotchet / 100) *
					(1.05 / 0.7)) * PlayState.SONG.speed

			if PlayState.pixelStage then
				prevNote.scale.y = prevNote.scale.y * 5
				prevNote.scale.y = prevNote.scale.y * (6 / self.height)
			end
			prevNote:updateHitbox()
		end
	else
		self.children = {}
	end
end

local safeZoneOffset = (10 / 60) * 1000

function Note:checkDiff()
	local instTime =
		(Note.chartingMode and ChartingState or PlayState).conductor.time
	return self.time > instTime - safeZoneOffset * self.lateHitMult and
		self.time < instTime + safeZoneOffset * self.earlyHitMult
end

function Note:update(dt)
	local instTime =
		(Note.chartingMode and ChartingState or PlayState).conductor.time
	self.canBeHit = self:checkDiff()

	if self.mustPress then
		if not self.ignoreNote and not self.wasGoodHit and
			self.time < instTime - safeZoneOffset then
			self.tooLate = true
		end
	end

	if self.tooLate and self.alpha > 0.3 then self.alpha = 0.3 end

	Note.super.update(self, dt)
end]]

return Note