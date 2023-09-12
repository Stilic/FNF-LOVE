local State = Group:extend()

State.persistentUpdate = false
State.persistentDraw = true
State.destroySubStates = true
State.bgColor = {0, 0, 0}
State.bgAlpha = 1
State.subState = nil
State.__requestedSubState = nil
State.__requestedSubStateReset = false

function State:enter() end

function State:draw()
    love.graphics.push()

    local r, g, b, a = love.graphics.getColor()

    local red, green, blue = self.bgColor[1], self.bgColor[2], self.bgColor[3]
    love.graphics.setColor(red, green, blue, self.bgAlpha)
    love.graphics.rectangle("fill", 0, 0, push:getWidth(), push:getHeight())

    love.graphics.setColor(r, g, b, a)

    love.graphics.pop()

    if self.persistentDraw or self.subState == nil then
        State.super.draw(self)
    end

    if self.subState ~= nil then
        self.subState:draw()
    end
end

function State:openSubState(subState)
    self.__requestedSubStateReset = true
    self.__requestedSubState = subState
end

function State:closeSubState()
    self.__requestedSubStateReset = true
end

function State:resetSubState()
    if self.subState ~= nil then
        if self.destroySubStates then
            self.subState:destroy()
        end
    end

    self.subState = self.__requestedSubState
    self.__requestedSubState = nil

    if self.subState ~= nil then
        self.subState.__parentState = self

        if not self.subState.__entered then
            self.subState.__entered = true
            self.subState:enter()
        end
    end
end

function State:destroy()
    if self.subState ~= nil then
        self.subState:destroy()
        self.subState = nil
    end
    State.super.destroy(self)
end

function State:tryUpdate(dt)
    if self.persistentUpdate or self.subState == nil then
        self:update(dt)
    end

    if self.__requestedSubStateReset then
        self.__requestedSubStateReset = false
        self:resetSubState()
    end
    if self.subState ~= nil then
        self.subState:tryUpdate(dt)
    end
end

return State
