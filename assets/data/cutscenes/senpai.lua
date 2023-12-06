local DialogueBox = require "funkin.gameplay.ui.dialoguebox"

local doof
local music
function create()
    local dialogue = love.filesystem.read(paths.getPath('songs/senpai/senpaiDialogue.txt')):split('\n')

    music = Sound():load(paths.getMusic('gameplay/Lunchbox'), 0.8, true, true)
    music:play()

    doof = DialogueBox(dialogue)
    doof:setScrollFactor()
    doof.cameras = {state.camHUD}
    doof.finishThing = function() state:startCountdown() close() end

    local black = Sprite(-100, -100):make(game.width * 2, game.height * 2,
                                            {0, 0, 0})
    black:setScrollFactor()
    state:add(black)

    for delay = 1, 7 do
        Timer.after(0.3 * delay, function()
            black.alpha = black.alpha - 0.15
            if black.alpha < 0 then
                state:remove(black)
                state:add(doof)
            end
        end)
    end
end

function postUpdate(dt)
    if controls:pressed('accept') and doof.isEnding then
        music:stop()
    end
end