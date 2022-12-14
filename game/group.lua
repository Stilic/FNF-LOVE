local Group = Object:extend()

function Group:new() self.members = {} end

function Group:add(obj)
    table.insert(self.members, obj)
    return obj
end

function Group:remove(obj)
    for i, o in pairs(self.members) do
        if o == obj then
            table.remove(self.members, i)
            return obj
        end
    end
    return obj
end

function Group:sort(func) return table.sort(self.members, func) end

function Group:recycle(class, factory, revive)
    if factory == nil then factory = class end
    if revive == nil then revive = true end

    local newObject
    for _, o in ipairs(self.members) do
        if o and not o.exists and (class == nil or (o.is and o:is(class))) then
            newObject = o
            break
        end
    end
    if not newObject then
        newObject = factory()
        self:add(newObject)
    else
        self:remove(newObject)
        self:add(newObject)
    end

    if revive then newObject:revive() end
    return newObject
end

function Group:update(dt, ...)
    for _, o in pairs(self.members) do
        local f = o.update
        if f then f(o, dt, ...) end
    end
end

function Group:draw(...)
    for _, o in pairs(self.members) do
        local resetCam = false
        if self.camera and not o.camera then
            resetCam = true
            o.camera = self.camera
        end
        local f = o.draw
        if f then f(o, ...) end
        if resetCam then o.camera = nil end
    end
end

function Group:beat(b, ...)
    for _, o in pairs(self.members) do
        local f = o.beat
        if f then f(o, b, ...) end
    end
end

return Group
