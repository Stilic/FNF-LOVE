local State = Group:extend()

function State:enter() end

function State:leave() Sprite.defaultCamera = nil end

return State
