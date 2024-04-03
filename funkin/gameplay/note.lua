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

	self.column = column
	self:setSkin(skin)
	self:setSustainTime(sustaintime)
end

function Note:_addAnim(...)
	(type(select(2, ...)) == 'table' and Sprite.addAnim or Sprite.addAnimByPrefix)(self, ...)
end

function Note:loadSkinData(data, name, column, noRgb)
	local anims, tex = data.animations, "skins/" .. name .. "/" .. data.sprite
	if anims then
		if data.isPixel then
			self:loadTexture(paths.getImage(tex), true, data.frameWidth, data.frameHeight)
		else
			self:setFrames(paths.getSparrowAtlas(tex))
		end

		for _, anim in ipairs(anims) do Note._addAnim(self, unpack(anim)) end
	else
		self:loadTexture(paths.getImage(tex))
	end

	self.blend = data.blend or self.blend

	local scale = data.scale
	self.scale.x, self.scale.y, self.scale.z, self.antialiasing = scale, scale, scale, data.antialiasing
	if self.antialiasing == nil then self.antialiasing = true end

	local props = data.properties
	props = props and column and props[column + 1] or props
	if props then for i, v in pairs(props) do self[i] = v end end

	if not noRgb and not data.disableRgb then
		local color = data.colors
		color = color and column and color[column + 1] or color
		self.shader = color and RGBShader.actorCreate(
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

	self:loadSkinData(skin.notes, name, col, true)

	if self.sustain then
		Note.loadSkinData(self.sustain, skin.sustains, name, col)
		Note.loadSkinData(self.sustainEnd, skin.sustainends, name, col)
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
	--[[
	local column, skin = self.column, self.skin
	local color = Note.colors[column + 1]

	local sustain, susend = self.sustain or Sprite(), self.sustainEnd or Sprite()
	self.sustain, self.sustainEnd = sustain, susend

	if skin == "pixel" then
		local tex = paths.getImage('skins/pixel/NOTE_assetsENDS')
	elseif skin == "normal" then
		susend:loadTextureFromSprite(self)
		sustain:loadTextureFromSprite(self)
		if column == 0 then
			susend:addAnimByPrefix("static", "pruple end hold")
		else
			susend:addAnimByPrefix("static", color .. " hold end")
		end
		sustain:addAnimByPrefix("static", color .. " hold piece")
	else
		susend:loadTextureFromSprite(self)
		sustain:loadTextureFromSprite(self)
		susend:addAnimByPrefix("static", color .. " hold end")
		sustain:addAnimByPrefix("static", color .. " hold piece")
	end

	susend:play("static"); self.updateHitbox(susend)
	sustain:play("static"); self.updateHitbox(sustain)
	sustain.__render, susend.__render = nil]]
end

function Note:createSustain()
	if self.sustain then return end
	local sustain, susend = Sprite(), Sprite()
	self.sustain, self.sustainEnd = sustain, susend

	local skin, col = self.skin, self.column
	Note.loadSkinData(sustain, skin.sustains, skin.skin, col)
	Note.loadSkinData(susend, skin.sustainends, skin.skin, col)

	susend:play("end"); self.updateHitbox(susend)
	sustain:play("hold"); self.updateHitbox(sustain)
	sustain.__render, susend.__render = __NIL__, __NIL__
end

function Note:destroySustain()
	if not self.sustain then return end

	self.sustainEnd:destroy()
	self.sustain:destroy()
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

local worldSpin = Actor.worldSpin
function Note:__render(camera)
	local grp, px, py, pz, pa, rot, sc = self.group, self.x, self.y, self.z, self.angle, self.rotation, self.scale
	local time, target, speed, psx, psy, psz, prx, pry, prz = self.time, self._targetTime, self.speed,
		sc.x, sc.y, sc.z, rot.x, rot.y, rot.z

	-- for now, its just a simple thing, no splines mod yet
	local path = Note.toPos(time - target, speed)
	local vx, vy, vz = px, py + path, pz

	local gx, gy, gz, gsx, gsy, gsz, grx, gry, grz, gox, goy, goz = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	if grp then
		gx, gy, gz, gsx, gsy, gsz, grx, gry, grz, gox, goy, goz = grp.x, grp.y, grp.z, grp.scale.x, grp.scale.y, grp.scale.z,
			grp.rotation.x, grp.rotation.y, grp.rotation.z, grp.origin.x, grp.origin.y, grp.origin.z

		self.angle, rot.x, rot.y, rot.z, sc.x, sc.y, sc.z = pa + grp.memberAngles,
			prx + grp.memberRotations.x, pry + grp.memberRotations.y, prz + grp.memberRotations.z,
			psx * grp.memberScales.x, psy * grp.memberScales.y, psz * grp.memberScales.z

		if grp.affectAngle then self.angle, rot.y, rot.y, rot.z = self.angle + grp.angle, rot.y + grx, rot.y + gry, rot.z + grz end
		if grp.affectScale then sc.x, sc.y, sc.z = sc.x * gsx, sc.y * gsy, sc.z * gsz end

		vx, vy, vz = worldSpin(vx * gsx, vy * gsy, vz * gsz, grx, gry, grz, gox, goy, goz)
	end
	self.x, self.y, self.z = vx + gx, vy + gy, vz + gz

	local sustain = self.sustain
	if sustain then
		local r, g, b, a = love.graphics.getColor()
		local shader = love.graphics.getShader()
		local blendMode, alphaMode = love.graphics.getBlendMode()
		local min, mag, anisotropy = self.texture:getFilter()
		local fov, mesh, verts, defaultShader = self.fov, self.mesh, self.__vertices, ActorSprite.defaultShader
		local drawSize, drawSizeOffset, sx, sy, sz = grp and grp.drawSize or 800, grp and grp.drawSizeOffset or 0, sc.x, sc.y, sc.z

		local susend, dont, y1, y2 = self.sustainEnd, false, path + py
		local height = Note.toPos(self.sustainTime, speed)

		-- Sustains
		local mode = sustain.antialiasing and "linear" or "nearest"
		local f, tw, th = sustain:getCurrentFrame(), sustain.texture:getWidth(), sustain.texture:getHeight()
		local fx, fy, fw, fh, uvx, uvy, uvw, uvh = 0, 0, tw, th, 0, 0, 1, 1
		if f then
			fx, fy = fx - f.offset.x, fy - f.offset.y
			uvx, uvy, fw, fh = f.quad:getViewport()
			uvx, uvy, uvw, uvh = uvx / tw, uvy / th, fw / tw, fh / th
		end
		fw, fh = fw * sx, fh * sy

		sustain.texture:setFilter(mode, mode, anisotropy)
		love.graphics.setShader(sustain.shader or defaultShader); love.graphics.setBlendMode(sustain.blend)
		love.graphics.setColor(sustain.color[1], sustain.color[2], sustain.color[3], sustain.alpha)
		mesh:setTexture(sustain.texture)

		local uvxw, uvyh, hfw = uvx + uvw, uvy + uvh, fw / 2
		while height > 0 do
			height, y1, y2 = height - fh, y1 + fh, y1
			dont = y1 > drawSize / 2 + drawSizeOffset - py
			if dont then break end

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
			verts[4][3], verts[4][4], verts[4][5] = uvx * vz, uvyh * vz, vz

			mesh:setDrawRange(1, 4)
			mesh:setVertices(verts)
			love.graphics.draw(mesh, 0, 0)
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

	self.x, self.y, self.z, self.angle, sc.x, sc.y, sc.z, rot.x, rot.y, rot.z = px, py, pz, pa, psx, psy, psz, prx, pry, prz
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