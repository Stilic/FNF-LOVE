---@class Group:Basic
local Group = Basic:extend("Group")

function Group:new()
    Group.super.new(self)
    self.members = {}
end

function Group:add(obj)
    table.insert(self.members, obj)
    return obj
end

function Group:remove(obj)
    for i, o in ipairs(self.members) do
        if o == obj then
            table.remove(self.members, i)
            break
        end
    end
    return obj
end

function Group:clear() for i in ipairs(self.members) do self.members[i] = nil end end

function Group:sort(func) return table.sort(self.members, func) end

function Group:recycle(class, factory, revive)
    if class == nil then class = Sprite end
    if factory == nil then factory = class end
    if revive == nil then revive = true end

    local newObject
    for _, o in ipairs(self.members) do
        if o and not o.exists and (o.is and o:is(class)) then
            newObject = o
            break
        end
    end
    if newObject then
        self:remove(newObject)
        if revive then newObject:revive() end
    else
        newObject = factory()
    end
    self:add(newObject)

    return newObject
end

function Group:update(dt)
    for _, o in ipairs(self.members) do
        if o.exists and o.active then
            local f = o.update
            if f then f(o, dt) end
        end
    end
end

function Group:draw()
    local oldDefaultCameras = Camera.__defaultCameras
    if self.cameras then Camera.__defaultCameras = self.cameras end

    for _, o in ipairs(self.members) do
        if o.exists and o.visible then
            local f = o.draw
            if f then f(o) end
        end
    end

    Camera.__defaultCameras = oldDefaultCameras
end

function Group:kill()
    for _, o in ipairs(self.members) do
        local f = o.kill
        if f then f(o) end
    end

    Group.super.kill(self)
end

function Group:revive()
    for _, o in ipairs(self.members) do
        local f = o.revive
        if f then f(o) end
    end

    Group.super.revive(self)
end

function Group:destroy()
    Group.super.destroy(self)

    for _, o in ipairs(self.members) do
        local f = o.destroy
        if f then f(o) end
    end
end

return Group
