---@class Graphic:Object
local Graphic = Object:extend("Graphic")

function Graphic:new(x, y, width, height, color, type, fill, lined)
	Graphic.super.new(self, x, y)

	self.width = width or 120
	self.height = height or 50

	self.color = color or Color.BLACK
	self.type = type or "rectangle"
	self.fill = fill or "fill"
	self.lined = lined or false

	self.config = {
		type = "open",
		angle = {0, 360},
		round = {0, 0},
		segments = 36,
		vertices = {}
	}

	self.line = {
		width = 6,
		color = {1, 1, 1, 1},
		join = "miter"
	}
end

function Graphic:updateHitbox()
	Graphic.super.updateHitbox(self)
	if self.type ~= "polygon" or #self.config.vertices == 0 then return end

	local min, max, v = math.huge, -math.huge
	for i = 1, #self.config.vertices, 2 do
		v = self.config.vertices[i]
		min = math.min(min, v)
		max = math.max(max, v)
	end
	self.width = max - min

	min, max = math.huge, -math.huge
	for i = 2, #self.config.vertices, 2 do
		v = self.config.vertices[i]
		min = math.min(min, v)
		max = math.max(max, v)
	end
	self.height = max - min
end

function Graphic:_getBoundary()
	local x, y = self.x or 0, self.y or 0
	if self.offset ~= nil then x, y = x - self.offset.x, y - self.offset.y end
	local w, h = self.width, self.height
	if self.lined then
		local lw = (self.line.width or 1)
		x, w = x - lw / 2, w + lw
		y, h = y - lw / 2, h + lw
	end

	return x, y, w, h, math.abs(self.scale.x * self.zoom.x), math.abs(self.scale.y * self.zoom.y),
		self.origin.x, self.origin.y
end

function Graphic:_canDraw()
	return (self.width > 0 or self.height > 0 or
		#self.config.vertices ~= 0) and Graphic.super._canDraw(self)
end

function Graphic:__render(camera)
	love.graphics.push("all")

	local line = self.line
	local linesize = line.width

	love.graphics.setLineStyle(self.antialiasing and "smooth" or "rough")
	love.graphics.setLineWidth(linesize)
	love.graphics.setLineJoin(line.join)

	local x, y, rad, sx, sy, ox, oy, kx, ky = self:setupDrawLogic(camera)
	local w, h = self.width, self.height

	local config = self.config
	local rnd, ang1, ang2 = config.round, 0, 0
	if config.angle then
		local pi180 = math.pi / 180
		ang1, ang2 = config.angle[1] * pi180, config.angle[2] * pi180
	end

	if self.fill == "line" then
		x, y = x + linesize / 2, y + linesize / 2
		w, h = w - linesize, h - linesize
	end
	local rad = math.min(w, h) / 2

	local color = self.color
	love.graphics.setShader(self.shader)
	love.graphics.setBlendMode(self.blend)
	love.graphics.setColor(color[1], color[2], color[3], self.alpha)

	love.graphics.translate(x, y)
	love.graphics.rotate(math.rad(self.angle))
	love.graphics.scale(sx, sy)
	love.graphics.shear(kx, ky)

	local function drawShape(type, fill)
		if type == "rectangle" then
			love.graphics.rectangle(fill, -ox, -oy, w, h, config.round[1], config.round[2], config.segments)
		elseif type == "polygon" and config.vertices then
			love.graphics.translate(-ox, -oy)
			love.graphics.polygon(fill, config.vertices)
		elseif type == "circle" then
			if w == h then
				love.graphics.circle(fill, rad - ox, rad - oy, rad, config.segments)
			else
				local x, y = w / 2, h / 2
				love.graphics.ellipse(fill, x - ox, y - oy, x, y, config.segments)
			end
		elseif type == "arc" then
			love.graphics.arc(fill, config.type, rad - ox, rad - oy, rad, ang1, ang2,
				math.ceil(config.segments * math.min((ang2 - ang1) / math.pi / 2, 1)))
		end
	end

	drawShape(self.type, self.fill)
	if self.lined then
		color = line.color
		love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * self.alpha)
		drawShape(self.type, "line")
	end

	love.graphics.pop()
end

return Graphic
