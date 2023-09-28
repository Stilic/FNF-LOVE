local SoundManager = {list = {}, dataCache = {}}

function SoundManager.cache(path)
    if string.startsWith(path, "./") then path = string.sub(path, 3) end
    if string.endsWith(path, "/") then path = string.sub(path, 1, -2) end

    if SoundManager.dataCache[path] then
        return SoundManager.dataCache[path]
    else
        local data = love.sound.newSoundData(path)
        SoundManager.dataCache[path] = data
        return data
    end
end

-- `asset` can be either a Source instance or a string.
function SoundManager.load(asset, volume, looped, autoRelease, onComplete)
    local sound = Sound(type(asset) == "string" and SoundManager.cache(asset) or
                            asset)
    if volume ~= nil then sound:setVolume(volume) end
    if looped ~= nil then sound:setLooping(looped) end
    sound.persist = autoRelease ~= nil and autoRelease or false
    sound.onComplete = onComplete
    table.insert(SoundManager.list, sound)
    print(#SoundManager.list)
    return sound
end

function SoundManager.play(...)
    local sound = SoundManager.load(...)
    sound:play()
    return sound
end

function SoundManager.update()
    for _, s in pairs(SoundManager.list) do s:update() end
end

function SoundManager.onFocus(focus)
    for _, s in pairs(SoundManager.list) do s:onFocus(focus) end
end

function SoundManager.destroy(force)
    for i, s in pairs(SoundManager.list) do
        if force or not s.persist then
            s:release()
            table.remove(SoundManager.list, i)
        end
    end
end

return SoundManager
