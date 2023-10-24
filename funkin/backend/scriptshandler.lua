local ScriptsHandler = Object:extend()

function ScriptsHandler:new() self.scripts = {} end

function ScriptsHandler:loadScript(file) table.insert(self.scripts, Script(file)) end

function ScriptsHandler:loadDirectory(...)
    for _, dir in ipairs({...}) do
        for _, file in ipairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                                    "data/" ..
                                                                        dir))) do
            if string.endsWith(file, '.lua') then
                self:loadScript(util.removeExtension(file))
            end
        end
    end
end

function ScriptsHandler:call(func, ...)
    for _, script in ipairs(self.scripts) do script:call(func, ...) end
end

function ScriptsHandler:set(variable, value)
    for _, script in ipairs(self.scripts) do script:set(variable, value) end
end

return ScriptsHandler
