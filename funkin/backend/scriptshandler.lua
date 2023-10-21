local ScriptsHandler = Object:extend()

ScriptsHandler.scripts = {}

function ScriptsHandler:loadDirectory(...)
    args = {...}

    for _, dir in ipairs(args) do
        for _, file in ipairs(love.filesystem.getDirectoryItems(paths.getPath("data/" ..dir))) do
            if string.endsWith(file, '.lua') then
                
                table.insert(self.scripts,
                Script(dir .. "/" .. util.removeExtension(file)))
            end
        end
    end
end

function ScriptsHandler:insert(object)
    table.insert(self.scripts, object)
end

function ScriptsHandler:load(directory)
    table.insert(self.scripts, Script(directory))
end

function ScriptsHandler:call(func, ...)
    for _, script in ipairs(self.scripts) do
        script:call(func, ...)
    end
end

function ScriptsHandler:set(variable, value)
    for _, script in ipairs(self.scripts) do
        script:set(variable, value)
    end
end

function ScriptsHandler:new()
    self.scripts = {}

    return {
        loadDirectory = function(...) self.loadDirectory(...) end,
        insert = function(...) self.insert(...) end,
        load = function(...) self.load(...) end,
        call = function(...) self.call(...) end,
        set = function(...) self.set(...) end
    }
end

return ScriptsHandler
