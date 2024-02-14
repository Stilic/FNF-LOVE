local target
function onCameraMove(event)
    if event.target == target then return end
    target = event.target

    if target == "bf" then
        Timer.tween((PlayState.conductor.stepCrotchet * 4 / 1000),
            game.camera, {zoom = 1}, 'in-out-elastic')
    else
        Timer.tween((PlayState.conductor.stepCrotchet * 4 / 1000),
            game.camera, {zoom = 1.3}, 'in-out-elastic')
    end
end