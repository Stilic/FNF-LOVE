local ScreenPrint = {prints = {}, game = {width = 0, height = 0}}

function ScreenPrint.init(width, height)
	ScreenPrint.game.width = width
	ScreenPrint.game.height = height
	ScreenPrint.scale = (love.window.getNativeDPIScale or love.window.getDPIScale)()
	ScreenPrint.font = love.graphics.newFont(20)
	ScreenPrint.bigfont = love.graphics.newFont(24)
end

function ScreenPrint.new(text, font)
	local n = #text
	font = font or (n < 14 and ScreenPrint.bigfont or ScreenPrint.font)

	local width = math.min(ScreenPrint.game.width - 72, font:getWidth(text))
	local _, lines = font:getWrap(text, width)
	local t = {
		text = text,
		font = font,
		timer = math.min(n * 0.11, 4),
		width = width,
		height = font:getHeight() * #lines,
		y = ScreenPrint.game.height + 8
	}

	table.insert(ScreenPrint.prints, t)
	return t
end

-- Though it isn't possible to resize in mobile but it's here for convenience
function ScreenPrint:resize(width, height)
	self.game.width = width
	self.game.height = height

	for _, t in ipairs(self.prints) do
		local twidth = math.min(width - 72, t.font:getWidth(t.text))
		local _, lines = t.font:getWrap(t.text, twidth)
		t.width, t.height = twidth, t.font:getHeight() * #lines
	end
end

function ScreenPrint:update(dt)
	local prints, y, t = self.prints, self.game.height + 8
	for i = #prints, 1, -1 do
		t = prints[i]
		t.timer = t.timer - dt

		y = y - t.height - 24
		t.y = math.lerp(y, t.y, math.exp(-dt * 6))
		if t.timer < -.3 then table.remove(prints, i) end
	end
end

function ScreenPrint:draw()
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()

	local scale, width, height = self.scale, self.game.width, self.game.height
	love.graphics.push()
	love.graphics.translate(width / 2, height)
	love.graphics.scale(self.scale)
	love.graphics.translate(-width / 2, -height)

	for _, t in ipairs(self.prints) do
		local y, w, h, a = t.y, t.width, t.height, math.min((t.timer + .3) / .3, 1)
		local x = (width - w) / 2

		local bx, by, bw, bh = x - 8, y - 8, w + 16, h + 16
		love.graphics.setColor(0.2, 0.2, 0.25, a * 0.7)
		love.graphics.rectangle("fill", bx, by, bw, bh, 15, 15, 36)
		love.graphics.setColor(0.4, 0.4, 0.45, a)
		love.graphics.rectangle("line", bx, by, bw, bh, 15, 15, 36)

		love.graphics.setColor(1, 1, 1, a)
		love.graphics.setFont(t.font)
		love.graphics.printf(t.text, x, y, w)
	end

	love.graphics.pop()

	love.graphics.setColor(r, g, b, a)
	love.graphics.setFont(font)
end

return ScreenPrint