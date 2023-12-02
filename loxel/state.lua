local Gamestate = require "loxel.lib.gamestate"

---@class State:Group
local State = Group:extend("State")

function State:new()
	State.super.new(self)

	self.persistentUpdate = false
	self.persistentDraw = true
end

function State:enter()
	
end

function State:update(dt) State.super.update(self, dt) end

function State:openSubstate(substate)
	self.substate = substate
	substate.parent = self
	Gamestate.push(substate)
end

function State:closeSubstate()
	if self.substate then
		Gamestate.pop(table.find(Gamestate.stack, self.substate))
		self.substate = nil
	end
end

return State
