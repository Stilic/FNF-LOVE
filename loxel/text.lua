---@class Text:Object
local Text = Object:extend("Text")

function Text:new(x, y, content, font, color, align, limit)
	Text.super.new(self, x, y)

	self.content = content
	self.font = font or love.graphics.getFont()
	self.color = color or {1, 1, 1}
	self.alignment = align or "left"
	self.limit = limit

	self.outline = {
		style = "normal",
		color = {0, 0, 0},
		width = 0,
		offset = {x = 0, y = 0}
	}

	self.__content = nil
	self.__font = nil
	self.__width = 0
	self.__height = 0
end

function Text:destroy()
	Text.super.destroy(self)

	self.font = nil
	self.content = nil
	self.outWidth = 0
end

function Text:__updateDimension()
	if self.__content == self.content and self.__font == self.font then
		return
	end
	self.__content = self.content
	self.__font = self.font

	self.__width = self.font:getWidth(self.content)
	local _, lines = self.font:getWrap(self.content, self.limit or self.__width)
	self.__height = self.font:getHeight() * #lines
end

function Text:getWidth()
	self:__updateDimension()
	return self.__width
end

function Text:getHeight()
	self:__updateDimension()
	return self.__height
end

function Text:setFont(font) self.font = font or love.graphics.getFont() end

function Text:setColor(color) self.color = color or {1, 1, 1} end

function Text:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self:getWidth()) / 2 end
	if axes:find("y") then self.y = (game.height - self:getHeight()) / 2 end
	return self
end

function Text:getMidpoint()
	return self.x + self.width / 2, self.y + self.height / 2
end

function Text:setOutline(style, width, offset, color)
	self.outline.style = style
	self.outline.width = width
	self.outline.offset = offset or {x = 0, y = 0}
	self.outline.color = color or {0, 0, 0}
end

function Text:_canDraw()
	return self.content ~= "" and Text.super._canDraw(self)
end

function Text:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local shader = self.shader and love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local font = love.graphics.getFont()

	local min, mag, anisotropy = self.font:getFilter()
	local mode = self.antialiasing and "linear" or "nearest"
	self.font:setFilter(mode, mode, anisotropy)

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)

	love.graphics.setShader(self.shader)

	love.graphics.setBlendMode(self.blend)

	love.graphics.setFont(self.font)

	local color = self.outline.color
	love.graphics.setColor(color[1], color[2], color[3],
		self.alpha)

	if self.outline.width > 0 then
		if self.outline.style == "normal" then
			for dx = -self.outline.width, self.outline.width do
				for dy = -self.outline.width, self.outline.width do
					love.graphics.printf(self.content, x + dx, y + dy,
						(self.limit or self:getWidth()),
						self.alignment)
				end
			end
		elseif self.outline.style == "simple" then
			local dx, dy = self.outline.offset.x, self.outline.offset.y
			love.graphics.printf(self.content, x + dx, y + dy,
				(self.limit or self:getWidth()),
				self.alignment)
		end
	end

	color = self.color
	love.graphics.setColor(color[1], color[2], color[3], self.alpha)
	love.graphics.printf(self.content, x, y, (self.limit or self:getWidth()),
		self.alignment)

	self.font:setFilter(min, mag, anisotropy)

	love.graphics.setColor(r, g, b, a)
	love.graphics.setFont(font)
	love.graphics.setBlendMode(blendMode, alphaMode)
	if self.shader then love.graphics.setShader(shader) end
end

return Text
