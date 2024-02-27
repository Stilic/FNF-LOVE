local ScreenPrint = {prints = {}, width = 0, height = 0}

function ScreenPrint.init(width, height)
	ScreenPrint.width = width
	ScreenPrint.height = height
	ScreenPrint.scale = love.graphics.getFixedScale()
	ScreenPrint.font = love.graphics.newFont(16 * ScreenPrint.scale)
	ScreenPrint.bigfont = love.graphics.newFont(20 * ScreenPrint.scale)
	ScreenPrint.visiblePrints = 0
end

local clock = 0
function ScreenPrint.new(text, font)
	local n = #text
	font = font or (n < 14 and ScreenPrint.bigfont or ScreenPrint.font)

	local width = math.min(ScreenPrint.width - 24 * ScreenPrint.scale, font:getWidth(text))
	local _, lines = font:getWrap(text, width)
	local t = {
		text = text,
		font = font,
		timer = math.min(n * 0.11, 4),
		width = width,
		height = font:getHeight() * #lines,
		y = ScreenPrint.height + 8,
		lastclock = clock
	}

	ScreenPrint.visiblePrints = ScreenPrint.visiblePrints + 1
	table.insert(ScreenPrint.prints, t)
	return t
end

-- Though it isn't possible to resize in mobile but it's here for convenience
function ScreenPrint:resize(width, height)
	self.width = width
	self.height = height

	for _, t in ipairs(self.prints) do
		local twidth = math.min(width - 24 * self.scale, t.font:getWidth(t.text))
		local _, lines = t.font:getWrap(t.text, twidth)
		t.width, t.height = twidth, t.font:getHeight() * #lines
	end
end

local dt = 0
function ScreenPrint:update(_dt) dt = dt + _dt end

local fill, line = "fill", "line"
local lastVisiblePrints = 0
function ScreenPrint:__render()
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()

	local prints, width, height, scale = self.prints, self.width, self.height, self.scale
	local bs1, bs2, offset = 8 * scale, 16 * scale, 24 * scale
	local y = height + bs1

	local visiblePrints, n, t = ScreenPrint.visiblePrints, #prints
	for i = n, n - visiblePrints + 1, -1 do
		t = prints[i]

		local timer = t.timer + t.lastclock - clock
		t.lastclock = clock
		if timer < -.3 then
			visiblePrints = visiblePrints - 1
			table.remove(prints, i)
		else
			y = y - t.height - offset
			local ty, th = math.lerp(y, t.y, math.exp(-dt * 6)), t.height
			if ty < -th then
				visiblePrints = n - i
				break
			end

			local tw, ta = t.width, math.min((t.timer + .3) / .3, 1)
			local tx = (width - tw) / 2

			local bx, by, bw, bh = tx - bs1, ty - bs1, tw + bs2, th + bs2
			local c1, c2 = 15 * scale, 36 * scale
			local color = Color.fromRGB(28, 26, 40)
			love.graphics.setColor(color[1], color[2], color[3], ta * 0.7)
			love.graphics.rectangle(fill, bx, by, bw, bh, c1, c1, c2)
			color = Color.fromRGB(130, 135, 174)
			love.graphics.setColor(color[1], color[2], color[3], ta)
			love.graphics.rectangle(line, bx, by, bw, bh, c1, c1, c2)

			love.graphics.setColor(1, 1, 1, ta)
			love.graphics.setFont(t.font)
			love.graphics.printf(t.text, tx, ty, tw)

			t.timer, t.y = timer, ty
		end
	end

	clock = n == 0 and 0 or clock + dt

	self.visiblePrints, lastVisiblePrints, dt = visiblePrints, visiblePrints, 0
	love.graphics.setColor(r, g, b, a)
	love.graphics.setFont(font)
end

return ScreenPrint
