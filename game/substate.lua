local SubState = State:extend()

SubState.__parentState = nil
SubState.__entered = false

function SubState:new() SubState.super.new(self) end

function SubState:draw() SubState.super.draw(self) end

function SubState:destroy()
    SubState.super.destroy(self)
    self.__parentState = nil
end

function SubState:close()
    if self.__parentState ~= nil and self.__parentState.subState == self then
        self.__parentState:closeSubState()
    end
end

return SubState
