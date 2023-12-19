function postCreate()
    for i, r in ipairs(state.receptors.members) do
        r:setFrames(paths.getSparrowAtlas('NOTE_assets_ourple'))
        r:setGraphicSize(math.floor(r.width * 0.7))

        local dir = Note.directions[r.data + 1]
        r:addAnimByPrefix("static", "arrow" .. string.upper(dir), 24, false)
        r:addAnimByPrefix("pressed", dir .. " press", 24, false)
        r:addAnimByPrefix("confirm", dir .. " confirm", 24, false)
        r:updateHitbox()

        r:play('static')
    end

    for i, n in ipairs(state.unspawnNotes) do
        local color = Note.colors[n.data + 1]
        n:setFrames(paths.getSparrowAtlas('NOTE_assets_ourple'))
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
        n.scrollOffset = {x = 0, y = 0}
        if n.isSustain and n.prevNote then
            n.scrollOffset.x = n.scrollOffset.x + n.width / 2
            n:play(color .. "holdend")
            n:updateHitbox()
            n.scrollOffset.x = n.scrollOffset.x - n.width / 2
            if n.prevNote.isSustain then
                n.prevNote:play(Note.colors[n.prevNote.data + 1] .. "hold")
                n.prevNote.scale.y = (n.prevNote.width / n.prevNote:getFrameWidth()) *
                                       ((PlayState.conductor.stepCrochet / 100) *
                                           (1.05 / 0.7)) * PlayState.SONG.speed
                n.prevNote:updateHitbox()
            end
        end
    end
end