local anims, add = {l = {-1, 0}, r = {1, 0}, u = {0, -1}, d = {0, 1}}, 18

function postUpdate()
    local mustHit = state:getCurrentSection().mustHit
    if mustHit ~= nil then
        local char
        if not mustHit then
            char = state.dad
        else
            char = state.boyfriend
        end
        local idx
        if char.curAnim and #char.curAnim.name > 4 and
            not char.curAnim.name:endsWith("miss") then
            idx = string.sub(char.curAnim.name, 5, 5)
        end
        if idx ~= nil then
            idx = string.lower(idx)
            local anim = anims[idx]
            state.camFollow.x, state.camFollow.y =
                state.camFollow.x + add * anim[1],
                state.camFollow.y + add * anim[2]
        end
    end
end
