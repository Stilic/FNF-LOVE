local SoundManager = {list = {}}

-- wip
SoundManager.volumeHandler = 1.0
SoundManager.__volume = nil
SoundManager.volume = 1
SoundManager.muted = false

function SoundManager.load(asset, volume, looped, autoRelease, onComplete)
    local sound = Sound(asset)
    if volume ~= nil then sound:setVolume(volume) end
    if looped ~= nil then sound:setLooping(looped) end
    sound.persist = (autoRelease ~= nil and autoRelease or false)
    sound.onComplete = onComplete
    table.insert(SoundManager.list, sound)
    return sound
end

function SoundManager.play(...)
    local sound = SoundManager.load(...)
    if SoundManager.volume ~= 1 then
        sound.__source:setVolume(sound.__source:getVolume() * SoundManager.volume)
    end
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

    if Keyboard.justPressed.ZERO then
        SoundManager.toggleMuted()
    elseif Keyboard.justPressed.PLUS then
        SoundManager.changeVolume(true)
    elseif Keyboard.justPressed.MINUS then
        SoundManager.changeVolume()
    end
end

function SoundManager.toggleMuted()
    SoundManager.muted = not SoundManager.muted

    if SoundManager.volumeHandler ~= nil then
        SoundManager.volumeHandler = SoundManager.muted and 0 or SoundManager.volume
    end
end

function SoundManager.changeVolume(increase)
    SoundManager.muted = false
    SoundManager.volume = increase ~= nil and math.min(1, SoundManager.volume + 0.1)
                                          or math.max(0, SoundManager.volume - 0.1)
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
