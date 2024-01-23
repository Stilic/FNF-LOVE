local ScreenPrint = {prints = {}, game = {width = 0, height = 0}}

function ScreenPrint.init(width, height)
	ScreenPrint.game.width = width
	ScreenPrint.game.height = height
	ScreenPrint.scale = love.graphics.getFixedScale()
	ScreenPrint.font = love.graphics.newFont(16 * ScreenPrint.scale)
	ScreenPrint.bigfont = love.graphics.newFont(20 * ScreenPrint.scale)
end

function ScreenPrint.new(text, font)
	local n = #text
	font = font or (n < 14 and ScreenPrint.bigfont or ScreenPrint.font)

	local width = math.min(ScreenPrint.game.width - 24 * ScreenPrint.scale, font:getWidth(text))
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
		local twidth = math.min(width - 24 * self.scale, t.font:getWidth(t.text))
		local _, lines = t.font:getWrap(t.text, twidth)
		t.width, t.height = twidth, t.font:getHeight() * #lines
	end
end

function ScreenPrint:update(dt)
	local prints, y, offset, t = self.prints, self.game.height + 8 * self.scale, 24 * self.scale
	for i = #prints, 1, -1 do
		t = prints[i]
		t.timer = t.timer - dt

		y = y - t.height - offset
		t.y = math.lerp(y, t.y, math.exp(-dt * 6))
		if t.timer < -.3 then table.remove(prints, i) end
	end
end

local fill, line = "fill", "line"
function ScreenPrint:draw()
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()

	local width, height, scale = self.game.width, self.game.height, self.scale
	--love.graphics.push()
	--love.graphics.translate(width / 2, height)
	--love.graphics.scale(self.scale)
	--love.graphics.translate(-width / 2, -height)

	for _, t in ipairs(self.prints) do
		local y, w, h, a = t.y, t.width, t.height, math.min((t.timer + .3) / .3, 1)
		local x = (width - w) / 2

		local bx, by, bw, bh = x - 8 * scale, y - 8 * scale, w + 16 * scale, h + 16 * scale
		local c1, c2 = 15 * scale, 36 * scale
		love.graphics.setColor(0.2, 0.2, 0.25, a * 0.7)
		love.graphics.rectangle(fill, bx, by, bw, bh, c1, c1, c2)
		love.graphics.setColor(0.4, 0.4, 0.45, a)
		love.graphics.rectangle(line, bx, by, bw, bh, c1, c1, c2)

		love.graphics.setColor(1, 1, 1, a)
		love.graphics.setFont(t.font)
		love.graphics.printf(t.text, x, y, w)
	end

	--love.graphics.pop()

	love.graphics.setColor(r, g, b, a)
	love.graphics.setFont(font)
end

return ScreenPrint