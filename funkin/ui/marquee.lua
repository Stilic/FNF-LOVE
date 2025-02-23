local Marquee = Text:extend("Marquee")

-- todo reweite this a bit I think -vk

function Marquee:new(x, y, limit, velocity, content, font, color)
	self.speed = velocity
	self.maxWidth = limit or 1000
	self.pauseTime = 1.5
	self.time = self.pauseTime
	self.scrollOffset = 0

	Marquee.super.new(self, x, y, content, font, color)
	self.spacing = 100
	self:__updateDimension()
end

function Marquee:update(dt)
	Marquee.super.update(self, dt)
	if self:getWidth() <= self.maxWidth then return end

	if self.time > 0 then
		self.time = self.time - dt
	else
		self.scrollOffset = self.scrollOffset + self.speed * dt
		if self.scrollOffset >= self.width + self.spacing then
			self.time = self.pauseTime
			self.scrollOffset = 0
		end
	end
end

function Marquee:__updateDimension()
	if self.__content == self.content and self.__font == self.font and
		self.__limit == self.limit
	then
		return
	end
	if self.canvas then
		self.canvas:release()
		self.quad0:release()
		self.quad1:release()
	end
	self.__content = self.content
	self.__limit = self.limit
	self.__font = self.font

	self.width = self.font:getWidth(self.content)
	self.height = self.font:getHeight()
	if self.limit ~= nil or self.width ~= 0 then
		local _, lines = self.font:getWrap(self.content, self.limit or self.width)
		self.height = self.height * #lines
	end

	if self.width <= (self.maxWidth or -1) then return end
	local _, _, w, h = self:_getBoundary()
	self.canvas = love.graphics.newCanvas(w + 1, h + 1)
	self.quad0 = love.graphics.newQuad(0, 0, w, h, w + 1, h + 1)
	self.quad1 = love.graphics.newQuad(0, 0, w, h, w + 1, h + 1)

	self.canvas:renderTo(bind(self, self.render))
end

function Marquee:render()
	love.graphics.push("all")

	local x, y, rad, sx, sy, ox, oy = 0, 0, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end
	local content, align, outline = self.content, self.alignment, self.outline
	local width, font, color = self.limit or self:getWidth(), self.font

	local content, align, outline = self.content, self.alignment, self.outline

	love.graphics.setFont(self.font)
	love.graphics.setBlendMode(self.blend, "alphamultiply")
	local min, mag, anisotropy = self.font:getFilter()
	local mode = self.antialiasing and "linear" or "nearest"

	if outline then
		color = outline.color
		love.graphics.setColor(Color.vec4(color, (color[4] or 1) * self.alpha))

		if outline.style == "simple" then
			love.graphics.printf(content,
				x + outline.offset.x, y + outline.offset.y,
				width, align, rad, sx, sy, ox, oy)
		elseif outline.width > 0 and outline.style == "normal" then
			local step = (2 * math.pi) / outline.precision
			for i = 1, outline.precision do
				local dx = math.cos(i * step) * outline.width
				local dy = math.sin(i * step) * outline.width
				if outline.antialiasing ~= nil then
					local omode = outline.antialiasing and "linear" or "nearest"
					self.font:setFilter(omode, omode, anisotropy)
				end
				love.graphics.printf(content, x + dx, y + dy,
					width, align, rad, sx, sy, ox, oy)
			end
		end
	end
	self.font:setFilter(mode, mode, anisotropy)

	color = self.bgColor
	local bgAlpha = #color > 3 and color[4] * self.alpha or self.alpha
	love.graphics.setColor(color[1], color[2], color[3], bgAlpha)
	love.graphics.rectangle("fill", x, y, self.width, self.height)

	color = self.color
	love.graphics.setColor(color[1], color[2], color[3], self.alpha)
	love.graphics.printf(content, x, y, width, align, rad, sx, sy, ox, oy)
	love.graphics.pop()
	self.font:setFilter(min, mag, anisotropy)
end

function Marquee:destroy()
	if self:getWidth() <= self.maxWidth then
		return Marquee.super.destroy(self)
	end
	self.canvas:release()
	self.quad0:release()
	self.quad1:release()
	Marquee.super.destroy(self)
end

function Marquee:__render(camera)
	if self:getWidth() <= self.maxWidth then
		return Marquee.super.__render(self, camera)
	end
	if not self.canvas then return end

	local min, mag, anisotropy, mode

	mode = self.antialiasing and "linear" or "nearest"
	min, mag, anisotropy = self.canvas:getFilter()
	self.canvas:setFilter(mode, mode, anisotropy)

	love.graphics.push("all")
	local x, y, rad, sx, sy, ox, oy, kx, ky = self:setupDrawLogic(camera)

	local w, h = self.canvas:getDimensions()
	w, h = w - 1, h - 1
	if not self.antialiasing then x, y = math.floor(x), math.floor(y) end

	local visibleWidth = math.min(self.maxWidth, w - self.scrollOffset)
	self.quad0:setViewport(self.scrollOffset, 0, visibleWidth, h)

	love.graphics.draw(self.canvas, self.quad0, x, y, rad, sx, sy, ox, oy, kx, ky)

	visibleWidth = math.min(self.maxWidth, w - self.scrollOffset + (self.spacing + w))
	self.quad1:setViewport(self.scrollOffset - (self.spacing + w), 0, visibleWidth, h)
	love.graphics.draw(self.canvas, self.quad1, x, y, rad, sx, sy, ox, oy, kx, ky)

	self.canvas:setFilter(min, mag, anisotropy)
	love.graphics.pop()
end


return Marquee
