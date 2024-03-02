---@class ButtonGroup:Button
local ButtonGroup = Button:extend("ButtonGroup")

function ButtonGroup:new()
	ButtonGroup.super.new(self)
	self.group = Group()
end

function ButtonGroup:add(button)
	return self.group:add(button)
end

function ButtonGroup:set(params)
	for _, button in pairs(self.group.members) do
		if button ~= nil then
			for key, value in pairs(params) do
				button[key] = value
			end
		end
	end
end

function ButtonGroup:update(dt)
	self.group:update(dt)
end

function ButtonGroup:draw()
	self.group:draw()
end

function ButtonGroup:check(x, y)
	for _, button in pairs(self.group.members) do
		if button ~= nil and not button.stunned and x >= button.x and
			x <= button.x + button.width and y >= button.y and
			y <= button.y + button.height then
			return button
		end
	end
	return nil
end

return ButtonGroup
