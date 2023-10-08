local SoundManager = {list = {}}

function SoundManager.load(asset, volume, looped, autoRelease, onComplete)
    local sound = Sound(asset)
    if volume ~= nil then sound:setVolume(volume) end
    if looped ~= nil then sound:setLooping(looped) end
    sound.persist = autoRelease ~= nil and autoRelease or false
    sound.onComplete = onComplete
    table.insert(SoundManager.list, sound)
    return sound
end

function SoundManager.play(...)
    local sound = SoundManager.load(...)
    sound:play()
    return sound
end

function SoundManager.update()
    for i = #SoundManager.list, 1, -1 do
        local s = SoundManager.list[i]
        if s.__source then
            s:update()
        else
            table.remove(SoundManager.list, i)
        end
    end
end

function SoundManager.onFocus(focus)
    for i = #SoundManager.list, 1, -1 do
        local s = SoundManager.list[i]
        if s.__source then
            s:onFocus(focus)
        else
            table.remove(SoundManager.list, i)
        end
    end
end

function SoundManager.destroy(force)
    table.remove(SoundManager.list, function(t, i)
        local s = t[i]
        local remove = force or not s.persist
        if remove then s:release() end
        return remove
    end)
end

return SoundManager
