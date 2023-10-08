local Basic = Object:extend()

function Basic:new()
    self.active = true
    self.visible = true

    self.alive = true
    self.exists = true

    self.cameras = nil
end

function Basic:kill()
    self.alive = false
    self.exists = false
end

function Basic:revive()
    self.alive = true
    self.exists = true
end

function Basic:destroy()
    self.exists = false
    self.cameras = nil
end

function Basic:draw()
    if self.__render then
        for _, c in ipairs(self.cameras or Camera.__defaultCameras) do
            if c.visible and c.exists then
                table.insert(c.__renderQueue, self)
            end
        end
    end
end

return Basic
