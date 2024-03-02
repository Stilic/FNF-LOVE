---@class ButtonGroup:Group
local ButtonGroup = Group:extend("ButtonGroup")

function ButtonGroup:new()
	ButtonGroup.super.new(self)
end

function ButtonGroup:set(params)
	for _, button in pairs(self.members) do
		if button ~= nil then
			for key, value in pairs(params) do
				button[key] = value
			end
		end
	end
end

function ButtonGroup:enable()
	for _, button in pairs(self.members) do
		button.stunned = false
		button.visible = true
	end
end

function ButtonGroup:disable()
	for _, button in pairs(self.members) do
		button.stunned = true
		button.visible = false
	end
end

return ButtonGroup
