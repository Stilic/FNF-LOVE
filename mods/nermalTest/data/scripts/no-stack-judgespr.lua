function goodNoteHit(n)
    if n.mustPress and not n.isSustain then
        state.judgeSprites:clear()
    end
end