local CameraManager = {list = {}, __defaults = {}}

function CameraManager.add(camera, defaultDrawTarget)
    table.insert(CameraManager.list, camera)
    if defaultDrawTarget == nil then defaultDrawTarget = true end
    if defaultDrawTarget then table.insert(CameraManager.__defaults, camera) end
    return camera
end

function CameraManager.remove(camera)
    if table.delete(CameraManager.list, camera) then
        table.delete(CameraManager.__defaults, camera)
    end
end

function CameraManager.reset(camera)
    local i = #CameraManager.list
    while i > 0 do
        table.delete(CameraManager.__defaults, CameraManager.list[i])
        table.remove(CameraManager.list, i)
        i = i - 1
    end

    if not camera then camera = Camera() end
    game.camera = CameraManager.add(camera)

    Camera.__defaultCameras = CameraManager.__defaults
end

function CameraManager.setDefaultDrawTarget(camera, value)
    local index = table.find(CameraManager.list, camera)
    if index then
        index = table.find(CameraManager.__defaults, camera)
        if value and not index then
            table.remove(CameraManager.__defaults, camera)
        elseif not value then
            table.remove(CameraManager.__defaults, index)
        end
    end
end

function CameraManager.update(dt)
    for _, cam in ipairs(CameraManager.list) do cam:update(dt) end
end

Camera.__defaultCameras = CameraManager.__defaults

return CameraManager
