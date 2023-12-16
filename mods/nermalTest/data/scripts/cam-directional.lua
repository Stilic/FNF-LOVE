local moveVal = 20

function postUpdate()
    state:cameraMovement()
    local section = PlayState.SONG.notes[curSection+1]
    if section then
        if section.mustHitSection then
            if state.boyfriend.curAnim.name == 'singLEFT' then
                state.camFollow.x = state.camFollow.x - moveVal
            elseif state.boyfriend.curAnim.name == 'singDOWN' then
                state.camFollow.y = state.camFollow.y + moveVal
            elseif state.boyfriend.curAnim.name == 'singUP' then
                state.camFollow.y = state.camFollow.y - moveVal
            elseif state.boyfriend.curAnim.name == 'singRIGHT' then
                state.camFollow.x = state.camFollow.x + moveVal
            end
        else
            if state.dad.curAnim.name == 'singLEFT' then
                state.camFollow.x = state.camFollow.x - moveVal
            elseif state.dad.curAnim.name == 'singDOWN' then
                state.camFollow.y = state.camFollow.y + moveVal
            elseif state.dad.curAnim.name == 'singUP' then
                state.camFollow.y = state.camFollow.y - moveVal
            elseif state.dad.curAnim.name == 'singRIGHT' then
                state.camFollow.x = state.camFollow.x + moveVal
            end
        end
    end
end