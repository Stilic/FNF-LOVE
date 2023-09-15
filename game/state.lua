local State = Group:extend()

function State:new()
    State.super.new(self)

    self.persistentUpdate = false
    self.persistentDraw = true
    self.bgColor = {0, 0, 0, 0}
end

function State:update(dt) State.super.update(self, dt) end

function State:draw()
    love.graphics.push()

    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3],
                           self.bgColor[4])
    love.graphics.rectangle("fill", 0, 0, push:getWidth(), push:getHeight())

    love.graphics.setColor(r, g, b, a)

    love.graphics.pop()

    State.super.draw(self)
end

function State:openSubState(subState)
    self.subState = subState
    subState.__parentState = self
    self.__defaultCamera = Camera.defaultCamera
    Camera.defaultCamera = Camera()
    Gamestate.push(subState)
end

function State:closeSubState()
    if self.subState then
        Camera.defaultCamera = self.__defaultCamera
        Gamestate.pop(table.find(Gamestate.stack, self.subState))
    end
end

-- ??
function State:leave() end

return State
