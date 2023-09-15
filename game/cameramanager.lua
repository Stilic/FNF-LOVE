local CameraManager = {list = {}, __defaults = {}}

function CameraManager.add(camera, defaultDrawTarget)
    CameraManager.list:insert(camera)
    if defaultDrawTarget == nil or defaultDrawTarget then
        CameraManager.__defaults:insert(camera)
    end
end

function CameraManager.remove(camera)
    if self.list:delete(camera) then self.__defaults:delete(camera) end
end

return CameraManager
