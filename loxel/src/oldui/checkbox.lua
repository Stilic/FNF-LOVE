local source = (...) and (...):gsub('%.oldui.checkbox$', '.') or ""
local Basic = require(source .. "basic")

local Checkbox = Basic:extend("Checkbox")

function Checkbox:new(x, y, size, callback)
	Checkbox.super.new(self)

	self.x = x or 0
	self.y = y or 0
	self.size = size or 20
	self.checked = false
	self.hovered = false
	self.callback = callback
	self.color = {1, 1, 1}
	self.alpha = 1
end

function Checkbox:update(dt)
	local mx, my = game.mouse.x, game.mouse.y
	self.hovered =
		(mx >= self.x and mx <= self.x + self.size and my >= self.y and my <=
			self.y + self.size)

	if game.mouse.justPressed then
		if game.mouse.justPressedLeft then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.LEFT)
		elseif game.mouse.justPressedRight then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.RIGHT)
		elseif game.mouse.justPressedMiddle then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.MIDDLE)
		end
	end
end

function Checkbox:__render()
	local r, g, b, a = love.graphics.getColor()

	love.graphics.setColor(self.color[1], self.color[2], self.color[3],
		self.alpha)
	love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)

	if self.hovered then
		love.graphics.setColor(self.color[1] * .2, self.color[2] * .2,
			self.color[3] * .2, self.alpha)
	else
		love.graphics.setColor(0, 0, 0, self.alpha)
	end

	love.graphics.rectangle("line", self.x, self.y, self.size, self.size)

	if self.checked then
		love.graphics.push()

		local checkX = self.x + self.size / 2
		local checkY = self.y + self.size / 2

		love.graphics.translate(checkX, checkY)
		love.graphics.setColor(0, 0, 0, self.alpha)

		local logo_position = {(-self.size) * 0.3, (-self.size) * -0.3}

		love.graphics.rotate(math.rad(45))
		love.graphics.rectangle("fill", logo_position[1], logo_position[2],
			(self.size * 0.5), (self.size * 0.2))
		love.graphics.rectangle("fill", 0, logo_position[2] * -2,
			(self.size * 0.2), (self.size * 1.1))

		love.graphics.pop()
	end

	love.graphics.setColor(r, g, b, a)
end

function Checkbox:mousepressed(x, y, button)
	if self.hovered then
		self.checked = not self.checked
		if self.callback then self.callback() end
	end
end

return Checkbox
