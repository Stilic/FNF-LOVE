local ActorSprite = Actor:extend("ActorSprite")
ActorSprite:implement(Sprite)

ActorSprite.vertexFormat = {
	{"VertexPosition", "float", 2},
	{"VertexTexCoord", "float", 3},
	{"VertexColor", "byte", 4}
}

local defaultShader
function ActorSprite.initShader()
	if defaultShader then return end
	defaultShader = love.graphics.newShader[[
		uniform Image MainTex;
		void effect() {
			love_PixelColor = Texel(MainTex, VaryingTexCoord.xy / VaryingTexCoord.z) * VaryingColor;
		}
	]]
end

function ActorSprite:new(x, y, z, texture)
	ActorSprite.super.new(self, x, y, z)
	ActorSprite.initShader()

	self.texture = Sprite.defaultTexture

	self.vertices = {
		{0, 0, 0, 0, 0},
		{1, 0, 0, 1, 0},
		{1, 1, 0, 1, 1},
		{0, 1, 0, 0, 1},
	}
	self.__vertices = {
		{0, 0, 0, 0, 1},
		{1, 0, 1, 0, 1},
		{1, 1, 1, 1, 1},
		{0, 1, 0, 1, 1},
	}
	self.mesh = love.graphics.newMesh(ActorSprite.vertexFormat, self.__vertices, "fan")

	self.clipRect = nil

	self.curAnim = nil
	self.curFrame = nil
	self.animFinished = nil
	self.animPaused = false

	self.__frames = nil
	self.__animations = nil

	self.__width, self.__height = self.width, self.height
	self.__rectangleMode = false

	if texture then self:loadTexture(texture) end
end

function ActorSprite:destroy()
	ActorSprite.super.destroy(self)

	self.texture = nil

	self.__frames = nil
	self.__animations = nil

	self.curAnim = nil
	self.curFrame = nil
	self.animFinished = nil
	self.animPaused = false
end

function ActorSprite:setDrawMode(mode)
	self.mesh:setDrawMode(mode)
end

function ActorSprite:getDrawMode()
	return self.mesh:getDrawMode()
end

function ActorSprite:destroy()
	ActorSprite.super.destroy(self)

	self.texture = nil

	self.__frames = nil
	self.__animations = nil

	self.curAnim = nil
	self.curFrame = nil
	self.animFinished = nil
	self.animPaused = false
end

function ActorSprite:update(dt)
	if self.__width ~= self.width or self.__height ~= self.height then
		self:setGraphicSize(self.width, self.height)
		self.__width, self.__height = self.width, self.height
	end

	if self.curAnim and not self.animFinished and not self.animPaused then
		self.curFrame = self.curFrame + dt * self.curAnim.framerate
		if self.curFrame >= #self.curAnim.frames + 1 then
			if self.curAnim.looped then
				self.curFrame = 1
			else
				self.curFrame = #self.curAnim.frames
				self.animFinished = true
			end
		end
	end

	if self.moves then
		self.velocity.x = self.velocity.x + self.acceleration.x * dt
		self.velocity.y = self.velocity.y + self.acceleration.y * dt
		self.velocity.z = self.velocity.z + self.acceleration.z * dt

		self.x = self.x + self.velocity.x * dt
		self.y = self.y + self.velocity.y * dt
		self.z = self.z + self.velocity.z * dt
	end
end

function ActorSprite:_canDraw()
	return self.texture ~= nil and (self.width ~= 0 or self.height ~= 0) and
		ActorSprite.super._canDraw(self)
end

function ActorSprite:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local shader = love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local min, mag, anisotropy, mode

	mode = self.antialiasing and "linear" or "nearest"
	min, mag, anisotropy = self.texture:getFilter()
	self.texture:setFilter(mode, mode, anisotropy)

	local f = self:getCurrentFrame()

	local x, y, z, rx, ry, rz, sx, sy, sz, ox, oy, oz =
		self.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - (camera.scroll.y * self.scrollFactor.y),
		self.z,
		self.rotation.x, self.rotation.y, self.rotation.z + self.angle,
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y, self.scale.z * self.zoom.z,
		self.origin.x, self.origin.y, self.origin.z

	x, y, z = x + ox - self.offset.x, y + oy - self.offset.y, z + oz - self.offset.z
	local uvx, uvy, uvw, uvh = 0, 0, 1, 1
	if f then
		local tw, th = self.texture:getWidth(), self.texture:getHeight()
		ox, oy = ox + f.offset.x, oy + f.offset.y
		uvx, uvy, uvw, uvh = f.quad:getViewport()
		uvx, uvy, uvw, uvh = uvx / tw, uvy / th, uvw / tw, uvh / th
	end
	ox, oy, oz = ox * sx, oy * sy, oz * sz

	if self.flipX then sx = -sx + 2 end
	if self.flipY then sy = -sy + 2 end
	sx = sx * self:getFrameWidth()
	sy = sy * self:getFrameHeight()

	local mesh, verts = self.mesh, self.__vertices
	local vert, vx, vy, vz
	for i, v in pairs(self.vertices) do
		vert = verts[i] or table.new(5, 0)
		verts[i] = vert

		vx, vy, vz = self.worldSpin(v[1] * sx, v[2] * sy, v[3] * sz, rx, ry, rz, ox, oy, oz)
		vert[1], vert[2], vert[5] = self.toScreen(vx + x - ox, vy + y - oy, vz + z - oz, self.fov)
		vert[3], vert[4] = (v[4] * uvw + uvx) * vert[5], (v[5] * uvh + uvy) * vert[5]
	end
	mesh:setDrawRange(1, #self.vertices)
	mesh:setVertices(verts)
	mesh:setTexture(self.texture)

	love.graphics.setShader(defaultShader or self.shader); love.graphics.setBlendMode(self.blend)
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
	love.graphics.draw(mesh, 0, 0)

	mesh:setTexture()
	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
	love.graphics.setShader(shader)
end

ActorSprite.updateHitbox = Sprite.updateHitbox
ActorSprite.centerOffsets = Sprite.centerOffsets
ActorSprite.fixOffsets = Sprite.fixOffsets
ActorSprite.centerOrigin = Sprite.centerOrigin

return ActorSprite