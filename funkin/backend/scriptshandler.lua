---@class ScriptsHandler:Classic
local ScriptsHandler = Classic:extend("ScriptsHandler")

---Creates a new script handler
function ScriptsHandler:new() self.scripts = {} end

---loads a script then adds it to the handler
---@param file string
function ScriptsHandler:loadScript(file) table.insert(self.scripts, Script(file)) end

---loads all scripts in a directory to the handler
---@param ... string
function ScriptsHandler:loadDirectory(...)
    for _, dir in ipairs({...}) do
        if Mods.currentMod then
            for _, file in ipairs(love.filesystem.getDirectoryItems(paths.getMods(
                                                                        dir))) do
                if file:endsWith('.lua') then
                    self:loadScript(util.removeExtension(dir .. "/" .. file))
                end
            end
        end
        for _, file in ipairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                                        dir))) do
            if file:endsWith('.lua') then
                self:loadScript(util.removeExtension(dir .. "/" .. file))
            end
        end
    end
end

---calls a function across all scripts
---@param func string
---@param ... any
function ScriptsHandler:call(func, ...)
    local retValue = {cancelled = false}
    for _, script in ipairs(self.scripts) do
        local retScript = script:call(func, ...)
        if (retScript == Script.Event_Cancel) then
            retValue.cancelled = true
        end
    end
    return retValue
end

---sets a variable across all scripts
---@param variable string
---@param value any
function ScriptsHandler:set(variable, value)
    for _, script in ipairs(self.scripts) do script:set(variable, value) end
end

return ScriptsHandler
