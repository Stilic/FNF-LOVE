local decodeJson = (require "lib.json").decode

local function readFile(key)
    if paths.exists(key, "file") then return love.filesystem.read(key) end
    return nil
end

local paths = {
    images = {},
    audio = {},
    atlases = {},
    fonts = {},
    persistantAssets = {"assets/music/freakyMenu.ogg"}
}

function paths.isPersistant(path)
    for _, k in pairs(paths.persistantAssets) do
        if path:startsWith(k) then return true end
    end
    return false
end

function paths.clearCache()
    for k, o in pairs(paths.images) do
        if not paths.isPersistant(k) then
            o:release()
            paths.images[k] = nil
        end
    end
    for k, o in pairs(paths.audio) do
        if not paths.isPersistant(k) then
            o:release()
            paths.audio[k] = nil
        end
    end
    for k, o in pairs(paths.atlases) do
        if not paths.isPersistant(k) then
            o.texture:release()
            for _, f in ipairs(o.frames) do f.quad:release() end
            paths.atlases[k] = nil
        end
    end
    collectgarbage()
end

function paths.getPath(key) return "assets/" .. key end

function paths.exists(path, infotype)
    local info = love.filesystem.getInfo(path)
    return info and info.type == infotype:lower()
end

function paths.getText(key)
    return readFile(paths.getPath("data/" .. key .. ".txt"))
end

function paths.getJSON(key)
    return decodeJson(readFile(paths.getPath(key .. ".json")))
end

function paths.getFont(key, size)
    if size == nil then size = 12 end

    local path = paths.getPath("fonts/" .. key)
    key = path .. "_" .. size
    local obj = paths.fonts[key]
    if obj then return obj end
    if paths.exists(path, "file") then
        obj = love.graphics.newFont(path, size)
        paths.fonts[key] = obj
        return obj
    end

    print('oh no its returning "font" null NOOOO: ' .. path)
    return nil
end

function paths.getImage(key)
    key = paths.getPath("images/" .. key .. ".png")
    local obj = paths.images[key]
    if obj then return obj end
    if paths.exists(key, "file") then
        obj = love.graphics.newImage(key)
        paths.images[key] = obj
        return obj
    end

    print('oh no its returning "image" null NOOOO: ' .. key)
    return nil
end

function paths.getAudio(key, stream)
    key = paths.getPath(key .. ".ogg")
    local obj = paths.audio[key]
    if obj then return obj end
    if paths.exists(key, "file") then
        obj = stream and love.audio.newSource(key, "stream") or
                  love.sound.newSoundData(key)
        paths.audio[key] = obj
        return obj
    end

    print('oh no its returning "audio" null NOOOO: ' .. key)
    return nil
end

function paths.getMusic(key) return paths.getAudio("music/" .. key, true) end

function paths.getSound(key) return paths.getAudio("sounds/" .. key, false) end

function paths.getInst(song)
    local daSong = paths.formatToSongPath(song)
    return paths.getAudio("songs/" .. daSong .. "/Inst", true)
end

function paths.getVoices(song)
    local daSong = paths.formatToSongPath(song)
    return paths.getAudio("songs/" .. daSong .. "/Voices", true)
end

function paths.getSparrowAtlas(key)
    local imgPath, xmlPath = key, paths.getPath("images/" .. key .. ".xml")
    key = paths.getPath("images/" .. key)
    local obj = paths.atlases[key]
    if obj then return obj end
    local img = paths.getImage(imgPath)
    if img and paths.exists(xmlPath, "file") then
        obj = Sprite.getFramesFromSparrow(img, readFile(xmlPath))
        paths.atlases[key] = obj
        return obj
    end

    return nil
end

function paths.getPackerAtlas(key)
    local imgPath, txtPath = key, paths.getPath("images/" .. key .. ".txt")
    key = paths.getPath("images/" .. key)
    local obj = paths.atlases[key]
    if obj then return obj end
    local img = paths.getImage(imgPath)
    if img and paths.exists(txtPath, "file") then
        obj = Sprite.getFramesFromPacker(img, readFile(txtPath))
        paths.atlases[key] = obj
        return obj
    end

    return nil
end

function paths.getAtlas(key)
    if paths.exists(paths.getPath('images/' .. key .. '.xml'), "file") then
        return paths.getSparrowAtlas(key)
    end
    return paths.getPackerAtlas(key)
end

function paths.getLua(key)
    local path = paths.getPath(key .. ".lua")
    if paths.exists(path, "file") then
        local chunk = love.filesystem.load(path)
        return chunk
    end
    return nil
end

local invalidChars = '[~&\\;:<>#]'
local hideChars = '[.,\'"%?!]'
function paths.formatToSongPath(path)
    return string.lower(string.gsub(string.gsub(path:gsub(' ', '-'),
                                                invalidChars, '-'), hideChars,
                                    ''))
end

return paths
