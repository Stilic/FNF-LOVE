local Script = Object:extend()

local chunkMt = {__index = _G}

function Script:new(path)
    self.path = path
    self.variables = {}
    self.closed = false

    local p = "data/" .. path

    local chunk = paths.getLua(p)
    if chunk then
        setfenv(chunk, setmetatable(self.variables, chunkMt))
        chunk()
    else
        print("script not found for " .. paths.getPath(p))
        self.closed = true
        return
    end

    p = path
    if not p:endsWith("/") then p = p .. "/" end
    self.variables["SCRIPT_PATH"] = p
    self.variables["close"] = function() self:close() end
    self.variables["state"] = game.getState()
end

function Script:set(var, value)
    if self.closed then return end

    self.variables[var] = value
end

function Script:call(func, ...)
    if self.closed then return true end
    local f = self.variables[func]
    if f and type(f) == "function" then
        local r = f(...)
        if r ~= nil and pcall(type, r) then return r end
        return true
    end
    return nil
end

function Script:close()
    self.closed = true
    self.variables = nil
end

return Script
