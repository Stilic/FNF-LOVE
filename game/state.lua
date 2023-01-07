local State = Object:extend()

function State:enter() end

function State:update(dt) end

function State:draw() end

function State:beat(b) end

function State:leave() Sprite.defaultCamera = nil end

return State
