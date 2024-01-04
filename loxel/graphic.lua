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
		round = {15, 15},
		segments = 36,
		vertices = nil
	}

	self.line = {
		width = 6,
		color = {1, 1, 1}, -- this only applies for lined graphics
		join = "miter"
	}
end

function Graphic:getGraphicMidpoint()
	return self.x + self.width / 2,
		self.y + self.height / 2
end

function Graphic:setSize(width, height)
	self.width = width or 0
	self.height = height or 0

	if self.type == "arc" or self.type == "circle" then
		self.config.radius = self.width
	end
end

function Graphic:updateDimensions()
	if self.type == "arc" or self.type == "circle" then
		self.width = 2 * self.config.radius
		self.height = 2 * self.config.radius
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

	love.graphics.setLineStyle(self.antialiasing and "smooth" or "rough")
	love.graphics.setLineWidth(self.line.width)
	love.graphics.setLineJoin(self.line.join)

	local x, y, w, h = self.x, self.y, self.width, self.height
	local vert = {}

	x, y = x - (camera.scroll.x * self.scrollFactor.x),
		y - (camera.scroll.y * self.scrollFactor.y)

	local ang1, ang2 = self.config.angle[1] * (math.pi / 180),
		self.config.angle[2] * (math.pi / 180)

	local rad, seg, rnd, type = self.config.radius, self.config.segments,
		self.config.round, self.config.type

	love.graphics.setShader(self.shader)
	love.graphics.setBlendMode(self.blend)
	love.graphics.setColor(self.color[1], self.color[2], self.color[3],
		self.alpha)

	love.graphics.push()
	love.graphics.rotate(math.rad(self.angle))

	if self.type == "rectangle" then
		love.graphics.rectangle(self.fill, x, y, w, h)
	elseif self.type == "roundrect" then
		love.graphics.rectangle(self.fill, x, y, w, h, rnd[1], rnd[2], seg)
	elseif self.type == "polygon" and self.config.vertices then
		love.graphics.translate(x, y)
		love.graphics.polygon(self.fill, self.config.vertices)
	elseif self.type == "circle" then
		love.graphics.circle(self.fill, x, y, rad, seg)
	elseif self.type == "arc" then
		love.graphics.arc(self.fill, type, x, y, rad, ang1, ang2, seg)
	end

	if self.lined then
		love.graphics.setColor(self.line.color[1], self.line.color[2],
			self.line.color[3], self.alpha)
		if self.type == "rectangle" then
			love.graphics.rectangle("line", x, y, w, h)
		elseif self.type == "roundrect" then
			love.graphics.rectangle("line", x, y, w, h, rnd[1], rnd[2], seg)
		elseif self.type == "polygon" and self.config.vertices then
			love.graphics.polygon("line", self.config.vertices)
		elseif self.type == "circle" then
			love.graphics.circle("line", x, y, rad, seg)
		elseif self.type == "arc" then
			love.graphics.arc("line", type, x, y, rad, ang1, ang2, seg)
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
