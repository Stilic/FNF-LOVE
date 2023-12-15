local Mods = {
    mods = {},
    currentMod = "empty"
}

function Mods.getBanner(mods)
    local loadedBanner = nil
    local banner = 'mods/' .. mods .. '/banner.png'
    local obj = paths.images[banner]
    if obj then loadedBanner = obj end
    if paths.exists(banner, "file") then
        obj = love.graphics.newImage(banner)
        paths.images[banner] = obj
        loadedBanner = obj
    else
        local emptyBanner = paths.getPath('images/menus/modsEmptyBanner.png')
        obj = paths.images[emptyBanner]
        if obj then loadedBanner = obj end
        if paths.exists(emptyBanner, "file") then
            obj = love.graphics.newImage(emptyBanner)
            paths.images[emptyBanner] = obj
            loadedBanner = obj
        end
    end
    return loadedBanner
end

function Mods.getMetadata(mods)
    local function readMetaFile()
        if paths.exists('mods/' .. mods .. '/meta.json', "file") then
            local json = (require "lib.json").decode(
                            love.filesystem.read('mods/' .. mods .. '/meta.json'))
            return json
        end
        return nil
    end
    local metaJson = readMetaFile() or {}
    local metadata = {
        name = metaJson.name or "Name",
        color = metaJson.color or "#1F1F1F",
        description = metaJson.description or "description",
        version = metaJson.version
    }
    return metadata
end

function Mods.loadMods()
    for _, dir in ipairs(love.filesystem.getDirectoryItems('mods')) do
        table.insert(Mods.mods, dir)
    end

    if game.save.data.curMods then
        Mods.currentMod = game.save.data.curMod
    end
end

return Mods