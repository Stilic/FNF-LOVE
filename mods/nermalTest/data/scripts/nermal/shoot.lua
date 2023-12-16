local killBf
function postCreate()
    killBf = Sprite(660, 420)
    killBf:setFrames(paths.getSparrowAtlas('killbf'))
    killBf:addAnimByPrefix('shot', 'BF hit', 24, false)
    killBf.visible = false
    state:add(killBf)
end

function step()
    if curStep == 808 then
        state.dad:playAnim('shootPOSE', true)
        state.dad.lastHit = math.floor(PlayState.conductor.time)
        state.dad.holdTime = 1000
    end
    if curStep == 816 then
        state.boyfriend.visible = false
        killBf.visible = true
        killBf:play('shot')
    end
end
