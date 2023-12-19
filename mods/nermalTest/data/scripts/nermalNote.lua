local nermalBlock = Timer.after(0, function() end)

local nerm1
local nerm2

local garf1
local garf2

function postCreate()
    for i, n in ipairs(state.unspawnNotes) do
        if n.altNote and n.altNote == 'nermalNote' then
            local color = Note.colors[n.data + 1]
            if PlayState.SONG.player2 == 'garfield' then
                n:setFrames(paths.getSparrowAtlas('notes/GARFNOTES'))
            else
                n:setFrames(paths.getSparrowAtlas('notes/nermalnote'))
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

    nerm1 = Sprite(-400, 500):loadTexture(paths.getImage('nermal jumpscare'))
    nerm1.scale = {x = 2, y = 0.5}
    nerm1:updateHitbox()
    nerm1.cameras = {state.camOther}

    nerm2 = Sprite(-400, -570):loadTexture(paths.getImage('nermal jumpscare'))
    nerm2.scale = {x = 2, y = 0.5 * -1}
    nerm2:updateHitbox()
    nerm2.cameras = {state.camOther}

    garf1 = Sprite(-400, 500):loadTexture(paths.getImage('garfield note jumpscare'))
    garf1.scale = {x = 2, y = 0.5}
    garf1:updateHitbox()
    garf1.cameras = {state.camOther}

    garf2 = Sprite(-400, -570):loadTexture(paths.getImage('garfield note jumpscare'))
    garf2.scale = {x = 2, y = 0.5 * -1}
    garf2:updateHitbox()
    garf2.cameras = {state.camOther}

    if PlayState.SONG.player2 == 'garfield' then
        garf1.alpha = 0
        state:add(garf1)
        garf2.alpha = 0
        state:add(garf2)
    else
        nerm1.alpha = 0
        state:add(nerm1)
        nerm2.alpha = 0
        state:add(nerm2)
    end
end

function postGoodNoteHit(n)
    if n.mustPress then
        if n.altNote and n.altNote == 'nermalNote' then
            state.health = state.health - 0.18
            state.healthBar:setValue(state.health)

            game.camera:shake(0.10, 0.5)
            state.camHUD:shake(0.10, 0.5)
            state.camOther:shake(0.10, 0.5)

            game.sound.play(paths.getSound('wow'))

            if PlayState.SONG.player2 == 'garfield' then
                Timer.cancelTweensOf(garf1)
                Timer.tween(1, garf1, {alpha = 1}, 'out-bounce')
                Timer.cancelTweensOf(garf2)
                Timer.tween(1, garf2, {alpha = 1}, 'out-bounce')
            else
                Timer.cancelTweensOf(nerm1)
                Timer.tween(1, nerm1, {alpha = 1}, 'out-bounce')
                Timer.cancelTweensOf(nerm2)
                Timer.tween(1, nerm2, {alpha = 1}, 'out-bounce')
            end

            Timer.cancel(nermalBlock)
            nermalBlock = Timer.after(10, function()
                if PlayState.SONG.player2 == 'garfield' then
                    Timer.tween(0.5, garf1, {alpha = 0})
                    Timer.tween(0.5, garf2, {alpha = 0})
                else
                    Timer.tween(0.5, nerm1, {alpha = 0})
                    Timer.tween(0.5, nerm2, {alpha = 0})
                end
            end)
        end
    end
end