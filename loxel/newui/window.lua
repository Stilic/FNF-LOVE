---@class Window:Object
local Window = Object:extend("Window")

function Window:new(x, y, width, height, title)
	Window.super.new(self, x, y)

    self.group = Group()
    self.members = self.group.members

	self.width = width or 400
	self.height = height or 200

	self.title = title or "Window"
	self.font = love.graphics.newFont(12)
	self.font:setFilter("nearest", "nearest")

	self.hovered = false
	self.callback = callback
    self.minimized = false
    self.dragging = false

	self.color = {0.3, 0.3, 0.3}
    self.barColor = {0.4, 0.4, 0.4}
    self.lineColor = {1, 1, 1}
	self.textColor = {1, 1, 1}

	self.lineSize = 3

    self.exitButton = newUI.UIButton(0, 0, 22, 22, 'X', function()
        self:destroy()
    end)
    self.exitButton.round = {4, 4}
    self.exitButton.color = Color.RED
    self.minButton = newUI.UIButton(0, 0, 22, 22, '-', function()
        self.minimized = not self.minimized
    end)
    self.minButton.round = {4, 4}
end

function Window:add(obj)
	obj.x = obj.x + self.x
	obj.y = obj.y + self.y
    return self.group:add(obj)
end

function Window:remove(obj) return self.group:remove(obj) end

function Window:update(dt)
    self.prevMouseX = self.prevMouseX or game.mouse.x
    self.prevMouseY = self.prevMouseY or game.mouse.y

    self.group:update(dt)

	local mx, my = game.mouse.x, game.mouse.y
	self.hovered =
		(mx >= self.x and mx <= self.x + self.width and my >= self.y and my <=
			self.y + self.height)

    local barHovered =
        (mx >= self.x and mx <= self.x + self.width and my >= self.y - 35 and my <=
            self.y)

	if game.mouse.justPressed then
		if game.mouse.justPressedLeft then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.LEFT)
		elseif game.mouse.justPressedRight then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.RIGHT)
		elseif game.mouse.justPressedMiddle then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.MIDDLE)
		end
	end

    if game.mouse.justPressed then
		if game.mouse.justPressedLeft then
			if barHovered then
                self.dragging = true
                self.prevMouseX = mx
                self.prevMouseY = my
            end
		end
	end

    if game.mouse.justReleased then
        if game.mouse.justReleasedLeft then
            self.dragging = false
        end
    end

    if self.dragging then
        local dx = mx - self.prevMouseX
        local dy = my - self.prevMouseY

        self.x = self.x + dx
        self.y = self.y + dy
        self:moved(dx, dy)

        self.prevMouseX = mx
        self.prevMouseY = my
    end

    self.exitButton:setPosition(self.x + self.width - 28, self.y - 29)
    self.exitButton:update()

    self.minButton:setPosition(self.x + self.width - 54, self.y - 29)
    self.minButton:update()
end

function Window:__render(camera)
	local cr, cg, cb, ca = love.graphics.getColor()
    local lineWidth = love.graphics.getLineWidth()

    if self.minimized then
        if self.lineSize > 0 then
            love.graphics.setLineWidth(self.lineSize)
            love.graphics.setColor(self.lineColor[1], self.lineColor[2], self.lineColor[3],
                self.alpha)
            love.graphics.rectangle("line", self.x, self.y - 35, self.width, 35, 8, 8)
            love.graphics.setLineWidth(lineWidth)
        end

        love.graphics.setColor(self.barColor[1], self.barColor[2], self.barColor[3],
            self.alpha)
        love.graphics.rectangle("fill", self.x, self.y - 35, self.width, 35, 8, 8)

        love.graphics.setColor(0, 0, 0, 0.1 / self.alpha)
        love.graphics.rectangle("fill", self.x, self.y - 18, self.width, 17, 8, 8)
    else
        if self.lineSize > 0 then
            love.graphics.setLineWidth(self.lineSize)
            love.graphics.setColor(self.lineColor[1], self.lineColor[2], self.lineColor[3],
                self.alpha)
            love.graphics.rectangle("line", self.x, self.y - 35, self.width, self.height + 35, 8, 8)
            love.graphics.setLineWidth(lineWidth)
        end

        love.graphics.setColor(self.barColor[1], self.barColor[2], self.barColor[3],
            self.alpha)
        love.graphics.rectangle("fill", self.x, self.y - 35, self.width, 50, 8, 8)

        love.graphics.setColor(self.color[1], self.color[2], self.color[3],
            self.alpha)
        love.graphics.rectangle("fill", self.x, self.y - 18, self.width, self.height + 18, 8, 8)

        love.graphics.setColor(0, 0, 0, 0.1 / self.alpha)
        love.graphics.rectangle("fill", self.x, self.y, self.width, 2)

        love.graphics.setColor(self.barColor[1], self.barColor[2], self.barColor[3],
            self.alpha)
        love.graphics.rectangle("fill", self.x, self.y - 18, self.width, 17)

        love.graphics.setColor(0, 0, 0, 0.1 / self.alpha)
        love.graphics.rectangle("fill", self.x, self.y - 18, self.width, 17)

        for _, obj in ipairs(self.members) do
            obj:__render(camera)
        end
    end

    love.graphics.setColor(self.textColor[1], self.textColor[2],
        self.textColor[3], self.alpha)
    love.graphics.print(self.title, self.font, self.x + 10, self.y - 25)

    self.exitButton:__render(camera)
    self.minButton:__render(camera)

	love.graphics.setColor(cr, cg, cb, ca)
end

function Window:mousepressed(x, y, button)
	if self.hovered and self.callback then self.callback() end
end

function Window:mousereleased(x, y, button)
    self.dragging = false
end

function Window:moved(dx, dy)
    for _, obj in ipairs(self.members) do
        if obj.moved then
            obj:moved(dx, dy)
        else
            obj.x = obj.x + dx
            obj.y = obj.y + dy
        end
    end
end

return Window