local Script = Object:extend()

local chunkMt = {__index = _G}

function Script:new(path)
    self.path = path
    self.__vars = {}

    local p = "data/" .. path
    self.__chunk = paths.getLua(p)
    if self.__chunk then
        setfenv(self.__chunk, setmetatable(self.__vars, chunkMt))
        self.__chunk = self.__chunk()
    else
        error("script not found for " .. p)
    end
end

function Script:set(name, val) self.__vars[name] = val end

function Script:get(name) return self.__vars[name] end

function Script:call(func, ...)
    local f = self.__chunk[func]
    if f and type(f) == "function" then
        return f(...)
    else
        return nil
    end
end

function Script:callReturn(func, ...)
    local r = self:call(func, ...)
    if r ~= nil and pcall(function() return type(r) end) then
        return r
    else
        return true
    end
end

return Script
