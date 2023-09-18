local SubState = State:extend()

function SubState:new() SubState.super.new(self) end

function SubState:belongsToParent()
    return self.__parentState and self.__parentState.subState == self
end

function SubState:update(dt)
    if self:belongsToParent() and self.__parentState.persistentUpdate then
        self.__parentState:update(dt)
    end
    SubState.super.update(self, dt)
end

function SubState:draw()
    if self:belongsToParent() and self.__parentState.persistentDraw then
        self.__parentState:draw()
    end
    SubState.super.draw(self)
end

function SubState:close()
    if self:belongsToParent() then self.__parentState:closeSubState() end
end

<<<<<<< HEAD
return SubState
=======
return SubState
>>>>>>> daaff1afa2faf923d68817a2f3ae4c5b62c57281
