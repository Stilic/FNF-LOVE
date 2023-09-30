local SubState = State:extend()

function SubState:new()
    SubState.super.new(self)
    self.bgColor = {0, 0, 0, 0}
end

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
    for _, c in pairs(self.cameras or Camera.__defaultCameras) do
        c:fill(self.bgColor[1], self.bgColor[2], self.bgColor[3],
               self.bgColor[4])
    end
    SubState.super.draw(self)
end

function SubState:close()
    if self:belongsToParent() then self.__parentState:closeSubState() end
end

return SubState
