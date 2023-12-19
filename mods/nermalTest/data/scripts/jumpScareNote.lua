local scary = Timer.after(0, function() end)

local garf

function postCreate()
    for i, n in ipairs(state.unspawnNotes) do
        if n.altNote and n.altNote == 'jumpScareNote' then
            local color = Note.colors[n.data + 1]
            if PlayState.SONG.song == 'Abuse' then
                n:setFrames(paths.getSparrowAtlas('notes/jumpscareNoteAsset2'))
                n.scrollOffset = {x = -15, y = -15}
            end
            if n.isSustain then
                if n.data == 0 then
                    n:addAnimByPrefix(color .. "holdend", "pruple end hold")
                else
                    n:addAnimByPrefix(color .. "holdend", color .. " hold end")
                end
                n:addAnimByPrefix(color .. "hold", color .. " hold piece")
            else
                n:addAnimByPrefix(color .. "Scroll", color .. "0")
            end
            n:setGraphicSize(math.floor(n.width * 0.7))
            n:updateHitbox()
            n:play(color .. "Scroll")
            if n.mustPress then n.ignoreNote = true end
        end
    end

    garf = Sprite(50, 0):loadTexture(paths.getImage('garfieldjumpscare'))
    garf.scale = {x = 1.8, y = 1}
    garf:updateHitbox()
    garf.cameras = {state.camOther}
    garf.alpha = 0
    state:add(garf)
end

function postGoodNoteHit(n)
    if n.mustPress then
        if n.altNote and n.altNote == 'jumpScareNote' then
            state.health = state.health - 1
            state.healthBar:setValue(state.health)

            game.camera:shake(0.10, 0.5)
            state.camHUD:shake(0.10, 0.5)
            state.camOther:shake(0.10, 0.5)

            game.sound.play(paths.getSound('sonic.exe laugh'))

            garf.alpha = 1

            Timer.cancel(scary)
            scary = Timer.after(0.5, function()
                Timer.tween(0.5, garf, {alpha = 0})
            end)
        end
    end
end