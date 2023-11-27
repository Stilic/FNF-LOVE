---@class Script:Classic
local Script = Classic:extend("Script")

local chunkMt = {__index = _G}

function Script:new(path, notFoundMsg)
    self.path = path
    self.variables = {}
    self.notFoundMsg = (notFoundMsg == nil and true or false)
    self.closed = false

    local p = path

    local chunk = paths.getLua(p)
    if chunk then
        setfenv(chunk, setmetatable(self.variables, chunkMt))
        chunk()
    else
        if not self.notFoundMsg then return end
        print("script not found for " .. paths.getPath(p))
        self.closed = true
        return
    end

    p = path
    if not p:endsWith("/") then p = p .. "/" end
    self:set("SCRIPT_PATH", p)
    self:set("close", function() self:close() end)
    self:set("state", game.getState())
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
