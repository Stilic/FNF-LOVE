---@class ScriptsHandler:Object
local ScriptsHandler = Object:extend()

---Creates a new script handler
function ScriptsHandler:new() self.scripts = {} end

---loads a script then adds it to the handler
---@param file string
function ScriptsHandler:loadScript(file) table.insert(self.scripts, Script(file)) end

---loads all scripts in a directory to the handler
---@param ... string
function ScriptsHandler:loadDirectory(...)
    for _, dir in ipairs({...}) do
        for _, file in ipairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                                    dir))) do
            if not file:endsWith('.lua') then return end
            self:loadScript(util.removeExtension(dir .. "/" .. file))
        end
    end
end

---calls a function across all scripts
---@param func string
---@param ... any
function ScriptsHandler:call(func, ...)
    for _, script in ipairs(self.scripts) do script:call(func, ...) end
end

---sets a variable across all scripts
---@param variable string
---@param value any
function ScriptsHandler:set(variable, value)
    for _, script in ipairs(self.scripts) do script:set(variable, value) end
end

return ScriptsHandler
