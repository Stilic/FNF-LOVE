local State = Group:extend()

function State:new()
	State.super.new(self)
end

function State:enter() end

function State:leave() Sprite.defaultCamera = nil end

return State
