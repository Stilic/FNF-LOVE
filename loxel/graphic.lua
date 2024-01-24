---@class Graphic:Object
local Graphic = Object:extend("Graphic")

function Graphic:new(x, y, width, height, color, type, fill, lined)
	Graphic.super.new(self, x, y)

	self.width = width or 0
	self.height = height or 0

	self.color = color or {0, 0, 0}
	self.type = type or "rectangle"
	self.fill = fill or "fill"
	self.lined = lined or false

	self.config = {
		type = "open",
		radius = 100,
		angle = {0, 180},
		round = {0, 0},
		segments = 36,
		vertices = nil
	}

	self.line = {
		width = 6,
		color = {1, 1, 1, 1}, -- this only applies for lined graphics
		join = "miter"
	}
end

function Graphic:getMidpoint()
	self:updateDimensions()
	return self.x + self.width / 2,
		self.y + self.height / 2
end

function Graphic:setSize(width, height)
	self.width = width or 0
	self.height = height or 0

	if self.type == "arc" or self.type == "circle" then
		self.config.radius = width / 2
	end
	self:updateDimensions()
end

function Graphic:updateDimensions()
	if self.type == "arc" or self.type == "circle" then
		self.width, self.height = 2 * self.config.radius, 2 * self.config.radius
		if self.fill == "line" then
			self.width = self.width + self.line.width
			self.height = self.height + self.line.width
		end
	end
end

function Graphic:_canDraw()
	return (self.width > 0 or self.height > 0 or self.config.radius > 0 or
		self.config.vertices) and Graphic.super._canDraw(self)
end

function Graphic:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local shader = self.shader and love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local lineStyle = love.graphics.getLineStyle()
	local lineWidth = love.graphics.getLineWidth()
	local lineJoin = love.graphics.getLineJoin()

	local line = self.line
	local linesize = line.width
	love.graphics.setLineStyle(self.antialiasing and "smooth" or "rough")
	love.graphics.setLineWidth(linesize)
	love.graphics.setLineJoin(line.join)

	local x, y, w, h = self.x, self.y, self.width, self.height
	local sx, sy = self.scale.x * self.zoom.x, self.scale.y * self.zoom.y
	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	local type, fill, config, pi180 = self.type, self.fill, self.config, math.pi / 180
	local rad, seg, rnd = config.radius, config.segments, config.round
	local verts, contype = config.vertices, config.type
	local ang1, ang2 = config.angle[1] * pi180, config.angle[2] * pi180
	if fill == "line" then x, y = x + linesize / 2, y + linesize / 2 end

	love.graphics.setShader(self.shader)
	love.graphics.setBlendMode(self.blend)
	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)

	love.graphics.push()
	love.graphics.rotate(math.rad(self.angle))
	love.graphics.scale(sx, sy)

	if type == "rectangle" then
		love.graphics.rectangle(fill, x, y, w, h, rnd[1], rnd[2], seg)
	elseif type == "circle" then
		love.graphics.circle(fill, x + rad, y + rad, rad, seg)
	elseif type == "arc" then
		love.graphics.arc(fill, contype, x + rad, y + rad, rad, ang1, ang2, seg)
	elseif type == "polygon" and verts then
		love.graphics.translate(x, y)
		love.graphics.polygon(fill, verts)
	end

	if self.lined then
		local linecolor = line.color
		love.graphics.setColor(linecolor[1], linecolor[2], linecolor[3], (linecolor[4] or 1) * self.alpha)
		if type == "rectangle" then
			love.graphics.rectangle("line", x, y, w, h, rnd[1], rnd[2], seg)
		elseif type == "circle" then
			love.graphics.circle("line", x + rad, y + rad, rad, seg)
		elseif type == "arc" then
			love.graphics.arc("line", contype, x + rad, y + rad, rad, ang1, ang2, seg)
		elseif type == "polygon" and verts then
			love.graphics.polygon("line", verts)
		end
	end

	love.graphics.pop()

	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
	love.graphics.setLineStyle(lineStyle)
	love.graphics.setLineWidth(lineWidth)
	love.graphics.setLineJoin(lineJoin)
	if self.shader then love.graphics.setShader(shader) end
end

return Graphic
