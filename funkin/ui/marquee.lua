local Marquee = Text:extend("Marquee")

function Marquee:new(x, y, limit, velocity, content, font, color)
	self.speed = velocity
	self.maxWidth = limit or 200
	self.pauseTime = 1.5
	self.pauseTimer = self.pauseTime
	self.scrollOffset = 0
	self.isScrolling = false

	Marquee.super.new(self, x, y, content, font, color)
	self.spacing = 50
end

function Marquee:update(dt)
	Marquee.super.update(self, dt)
	if self.width <= self.maxWidth then return end

	if not self.isScrolling then
		self.pauseTimer = self.pauseTimer - dt
		if self.pauseTimer <= 0 then
			self.isScrolling = true
		end
	else
		self.scrollOffset = self.scrollOffset + self.speed * dt
		if self.scrollOffset >= self.textWidth + self.spacing then
			self.scrollOffset = 0
			self.pauseTimer = self.pauseTime
			self.isScrolling = false
		end
	end
	if self.canRender and self.isScrolling then -- insane shit but its fucked up on render due to transformations
	-- no love.graphics.origin() won't do it
		self.canvas:renderTo(function()
			love.graphics.clear(0, 0, 0, 0)
			self:__renderText(-self.scrollOffset)
			self:__renderText(-self.scrollOffset + self.textWidth + self.spacing)
		end)
		self.canRender = nil
	end
end

function Marquee:__updateDimension()
	if self.__content == self.content and self.__font == self.font and
		self.__limit == self.limit then return end
	self.__content = self.content
	self.__limit = self.limit
	self.__font = self.font

	self.width = self.font:getWidth(self.content)
	self.height = self.font:getHeight()
	if self.limit ~= nil or self.width ~= 0 then
		local _, lines = self.font:getWrap(self.content, self.limit or self.width)
		self.height = self.height * #lines
	end

	if self.width > (self.maxWidth or -1) then
		self:updateCanvas()
	end
end

function Marquee:updateCanvas()
	if self.canvas then self.canvas:release() end
	self.textWidth = self.font:getWidth(self.content)
	self.textHeight = self.font:getHeight()
	if self.limit ~= nil then
		local _, lines = self.font:getWrap(self.content, self.limit)
		self.textHeight = self.textHeight * #lines
	end
	self.canvas = love.graphics.newCanvas(self.maxWidth, self.textHeight)
	self.canvas:renderTo(function()
		love.graphics.clear(0, 0, 0, 0)
		self:__renderText(-self.scrollOffset)
		self:__renderText(-self.scrollOffset + self.textWidth + self.spacing)
	end)
end

function Marquee:__renderText(x)
	love.graphics.push("all")

	local rad, sx, sy, ox, oy = 0, 1, 1
	if not self.antialiasing then x = math.floor(x) end

	local content, align, outline = self.content, self.alignment, self.outline
	local width, font = self.limit or self.textWidth, self.font

	love.graphics.setFont(self.font)
	local min, mag, anisotropy = self.font:getFilter()
	local mode = self.antialiasing and "linear" or "nearest"

	if outline then
		local outlineColor = outline.color
		love.graphics.setColor(Color.vec4(outlineColor, (outlineColor[4] or 1)))
		if outline.style == "simple" then
			love.graphics.printf(content,
				x + outline.offset.x, outline.offset.y,
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
				love.graphics.printf(content, x + dx, dy,
					width, align, rad, sx, sy, ox, oy)
			end
		end
	end
	self.font:setFilter(mode, mode, anisotropy)

	local color = self.color
	love.graphics.setColor(color[1], color[2], color[3], 1)
	love.graphics.printf(content, x, 0, width, align, rad, sx, sy, ox, oy)

	self.font:setFilter(min, mag, anisotropy)
	love.graphics.pop()
end

function Marquee:__render(camera)
	if self.width <= self.maxWidth then
		return Marquee.super.__render(self, camera)
	end

	self.canRender = true

	love.graphics.push("all")
	local r, g, b = love.graphics.getColor()
	local x, y, rad, sx, sy, ox, oy, kx, ky = self:setupDrawLogic(camera, false)
	if not self.antialiasing then x, y = math.floor(x), math.floor(y) end
	love.graphics.setShader(self.shader)
	local mode = self.antialiasing and "linear" or "nearest"
	self.canvas:setFilter(mode, mode)
	-- love.graphics.setBlendMode(self.blend, "premultiplied")
	love.graphics.setColor(r, g, b, self.alpha)
	love.graphics.draw(self.canvas, x, y, rad, sx, sy, ox, oy, kx, ky)
	love.graphics.pop()
end

function Marquee:destroy()
	if self.canvas then self.canvas:release() end
	Marquee.super.destroy(self)
end

return Marquee