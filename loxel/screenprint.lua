local function makePopup(x, y, w, h)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.rectangle("fill", x, y, w, h, 15, 15, 36)
	love.graphics.setColor(r + 0.2, g + 0.2, b + 0.2)
	love.graphics.rectangle("line", x, y, w, h, 15, 15, 36)
	love.graphics.setColor(r, g, b, a)
end

local ScreenPrint = {prints = {}, game = {width = 0, height = 0}}

function ScreenPrint.init(width, height)
	ScreenPrint.game.width = width
	ScreenPrint.game.height = height
end

function ScreenPrint.new(text, font)
	for _, current in ipairs(ScreenPrint.prints) do
		if current.text ~= text then
			current.text = current.text .. "\n" .. text
			current.timer = math.max(current.timer, (string.len(current.text) * 0.03))

			local _, wt = current.font:getWrap(current.text, current.bg.width - 36)
			current.bg.height = current.font:getHeight() * #wt + 36
			current.height = current.font:getHeight() * #wt
			current.bg.x = (love.graphics.getWidth() - current.bg.width) / 2
			current.bg.width = math.min(ScreenPrint.game.width - 72,
				font:getWidth(current.text) + 36)

			return
		end
	end

	local print = {
		text = text,
		font = (font or love.graphics.getFont()),
		height = 0,
		bg = {
			x = 0,
			y = ScreenPrint.game.height,
			width = math.min(ScreenPrint.game.width - 72, font:getWidth(text) + 36),
			height = 0,
			offset = {x = 0, y = 0},
			color = {0.2, 0.2, 0.25}
		},
		timer = math.max(2, (string.len(text) * 0.03))
	}

	local _, wt = print.font:getWrap(print.text, print.bg.width - 36)
	print.bg.x = (love.graphics.getWidth() - print.bg.width) / 2
	print.bg.height = print.font:getHeight() * #wt + 36
	print.bg.y = print.bg.y + print.bg.height
	print.height = print.font:getHeight() * #wt

	table.insert(ScreenPrint.prints, print)
end

function ScreenPrint.update(dt)
	for i = #ScreenPrint.prints, 1, -1 do
		local print = ScreenPrint.prints[i]
		print.timer = print.timer - dt

		if print.timer > 0 then
			print.bg.y = math.lerp(ScreenPrint.game.height - 15 - print.bg.height,
				print.bg.y, math.exp(-dt * 12))
		else
			print.bg.y = math.lerp(ScreenPrint.game.height + print.bg.height + 5,
				print.bg.y, math.exp(-dt * 6))
		end

		if print.bg.y >= ScreenPrint.game.height + print.bg.height and print.timer < 0 then
			table.delete(ScreenPrint.prints, print)
		end
	end
end

function ScreenPrint.draw()
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()
	for _, print in ipairs(ScreenPrint.prints) do
		local x, y = print.bg.x - print.bg.offset.x, print.bg.y - print.bg.offset.y
		love.graphics.setColor(print.bg.color)
		makePopup(x, y, print.bg.width, print.bg.height)

		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(print.font)

		local center = (print.bg.height - print.height) / 2
		love.graphics.printf(print.text, x + (36 / 2), y + center,
			print.bg.width - 36)
	end
	love.graphics.setColor(r, g, b, a)
	love.graphics.setFont(font)
end

return ScreenPrint
