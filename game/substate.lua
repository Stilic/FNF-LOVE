local SubState = State:extend()

function SubState:new()
    SubState.super.new(self)
    self.__camera = {Camera()}
end

function SubState:belongsToParent()
    return self.__parentState and self.__parentState.subState == self
end

function SubState:update(dt)
    if self:belongsToParent() and self.__parentState.persistentUpdate then
        self.__parentState:update(dt)
    end

    self.__camera[1]:update(dt)
    SubState.super.update(self, dt)
end

function SubState:draw()
    if self:belongsToParent() and self.__parentState.persistentDraw then
        self.__parentState:draw()
    end

    local oldDefaultCameras = Camera.__defaultCameras
    Camera.__defaultCameras = self.__camera

    SubState.super.draw(self)

    Camera.__defaultCameras = oldDefaultCameras
end

function SubState:close()
    if self:belongsToParent() then self.__parentState:closeSubState() end
end

return SubState
