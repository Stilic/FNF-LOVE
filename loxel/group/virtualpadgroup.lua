---@class VirtualPadGroup:Group
local VirtualPadGroup = Group:extend("VirtualPadGroup")

function VirtualPadGroup:new()
	VirtualPadGroup.super.new(self)
end

function VirtualPadGroup:set(params)
	for _, VirtualPad in pairs(self.members) do
		if VirtualPad ~= nil then
			for key, value in pairs(params) do
				VirtualPad[key] = value
			end
		end
	end
end

function VirtualPadGroup:enable()
	for _, VirtualPad in pairs(self.members) do
		VirtualPad.stunned = false
		VirtualPad.visible = true
	end
end

function VirtualPadGroup:disable()
	for _, VirtualPad in pairs(self.members) do
		VirtualPad.stunned = true
		VirtualPad.visible = false
	end
end

return VirtualPadGroup
