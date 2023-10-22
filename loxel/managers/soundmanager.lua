local SoundManager = {list = Group(), music = nil}

function SoundManager.play(asset, volume, looped, autoKill, onComplete)
    local sound = SoundManager.list:recycle(Sound):load(asset)
    if volume ~= nil then sound:setVolume(volume) end
    if looped ~= nil then sound:setLooping(looped) end
    sound.autoKill = autoKill ~= nil and autoKill or true
    sound.onComplete = onComplete
    sound:play()
    return sound
end

function SoundManager.playMusic(asset, volume, looped)
    local sound = Sound():load(asset)
    if volume ~= nil then sound:setVolume(volume) end
    if looped ~= nil then sound:setLooping(looped) end
    sound.persist = true
    SoundManager.music = sound
    sound:play()
    return sound
end

function SoundManager.update()
    if SoundManager.music and SoundManager.music.exists and
        SoundManager.music.active then SoundManager.music:update() end
    SoundManager.list:update()
end

function SoundManager.onFocus(focus)
    if SoundManager.music and SoundManager.music.exists and
        SoundManager.music.active then SoundManager.music:onFocus(focus) end
    for _, s in ipairs(SoundManager.list.members) do
        if s.exists then s:onFocus(focus) end
    end
end

function SoundManager.destroy(force)
    table.remove(SoundManager.list.members, function(t, i)
        local s = t[i]
        local remove = force or not s.persist
        if remove then s:destroy() end
        return remove
    end)
end

return SoundManager
