local SoundManager = {list = {}}

SoundManager.oldVolume = nil
SoundManager.volume = 1
SoundManager.muted = false

SoundManager.__soundTrayTimer = 0
SoundManager.showSoundTray = false

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
    sound:play()
    return sound
end

function SoundManager.update(dt)
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

    if SoundManager.__soundTrayTimer > 0 then
        SoundManager.__soundTrayTimer = SoundManager.__soundTrayTimer - dt
        SoundManager.showSoundTray = true
    else
        SoundManager.showSoundTray = false
    end
end

function SoundManager.toggleMuted()
    if SoundManager.muted then
        SoundManager.volume = SoundManager.oldVolume
        SoundManager.oldVolume = nil
        for i = #SoundManager.list, 1, -1 do
            local s = SoundManager.list[i]
            s:unmute()
        end
        SoundManager.play(paths.getSound('beep'))
    else
        for i = #SoundManager.list, 1, -1 do
            local s = SoundManager.list[i]
            s:mute()
        end
        SoundManager.oldVolume = SoundManager.volume
        SoundManager.volume = 0
    end
    SoundManager.muted = not SoundManager.muted

    SoundManager.__soundTrayTimer = 2
end

function SoundManager.changeVolume(increase)
    if SoundManager.volume < 0 or SoundManager.volume > 1 then return end

    if SoundManager.muted then
        SoundManager.muted = false
        SoundManager.volume = SoundManager.oldVolume
        SoundManager.oldVolume = nil
        for i = #SoundManager.list, 1, -1 do
            local s = SoundManager.list[i]
            s:unmute()
        end
    end
    SoundManager.volume = increase ~= nil and math.min(1, SoundManager.volume + 0.1)
                                          or math.max(0, SoundManager.volume - 0.1)
    if math.abs(SoundManager.volume) < 1e-10 then SoundManager.volume = 0 end
    SoundManager.play(paths.getSound('beep'))

    for i = #SoundManager.list, 1, -1 do
        local s = SoundManager.list[i]
        s.__source:setVolume(s.__volume * SoundManager.volume)
    end

    SoundManager.__soundTrayTimer = 2
end

function SoundManager.drawSoundTray()
    local r, g, b, a = love.graphics.getColor()
    local rectWidth, rectHeight = 180, 80
    local rectX, rectY = (game.width - rectWidth) / 2, 0

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", rectX, rectY, rectWidth, rectHeight)

    local barWidth, barHeight = 10, 26
    for i = 0, 1, 0.1 do
        if i <= SoundManager.volume then
            local fakeindex = i + 0.1
            local barX, barY = (fakeindex * 142) + rectX, (barHeight -
                                                        (barHeight * fakeindex)) + 20
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", barX, barY, barWidth, (barHeight * fakeindex))
        end
    end

    local font = love.graphics.newFont(24)
    local percent = SoundManager.volume * 100
    local text = tostring(percent) .. '%'
    local textWidth = font:getWidth(text)
    local textX, textY = (game.width - textWidth) / 2, rectY + barHeight + 24
    love.graphics.print(text, font, textX, textY)

    love.graphics.setColor(r, g, b, a)
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
