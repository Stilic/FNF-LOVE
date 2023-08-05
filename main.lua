io.stdout:setvbuf("no")

require "lib.override"

Object = require "lib.classic"
push = require "lib.push"
Timer = require "lib.timer"
Gamestate = require "lib.gamestate"

paths = require "game.paths"
util = require "game.util"

Script = require "game.script"
Conductor = require "game.conductor"

Camera = require "game.camera"

Sprite = require "game.sprite"
Bar = require "game.bar"
Group = require "game.group"

Note = require "game.gameplay.ui.note"
Receptor = require "game.gameplay.ui.receptor"

Stage = require "game.gameplay.stage"
Character = require "game.gameplay.character"

State = require "game.state"
TitleState = require "game.states.title"
PlayState = require "game.states.play"

-- local function onBeat(b) Gamestate.beat(b) end

-- function setMusic(source)
--     music = source:onBeat(onBeat)
--     return source
-- end

-- function resetMusic()
--     setMusic(paths.getMusic("freakyMenu")):setBPM(102).looping = true
-- end

controls = (require "lib.baton").new({
    controls = {
        ui_left = {"key:left", "key:a", "axis:leftx-", "button:dpleft"},
        ui_down = {"key:down", "key:s", "axis:lefty+", "button:dpdown"},
        ui_up = {"key:up", "key:w", "axis:lefty-", "button:dpup"},
        ui_right = {"key:right", "key:d", "axis:leftx+", "button:dpright"},

        note_left = {
            "key:left", "key:d", "axis:leftx-", "button:dpleft", "button:x"
        },
        note_down = {
            "key:down", "key:f", "axis:lefty+", "button:dpdown", "button:a"
        },
        note_up = {"key:up", "key:j", "axis:lefty-", "button:dpup", "button:y"},
        note_right = {
            "key:right", "key:k", "axis:leftx+", "button:dpright", "button:b"
        },

        accept = {"key:space", "key:return", "button:a", "button:start"},
        back = {"key:backspace", "key:escape", "button:b"},
        pause = {"key:return", "key:escape", "button:start"},
        reset = {"key:r", "button:leftstick"}
    },
    joystick = love.joystick.getJoysticks()[1]
})

local fade, fadeTimer
function fadeOut(time, callback)
    if fadeTimer then Timer.cancel(fadeTimer) end

    fade = {
        height = push.getHeight() * 2,
        texture = util.newGradient("vertical", {0, 0, 0}, {0, 0, 0},
                                   {0, 0, 0, 0})
    }
    fade.y = -fade.height
    fadeTimer = Timer.tween(time, fade, {y = 0}, "linear", function()
        fade.texture:release()
        fade = nil
        if callback then callback() end
    end)
end

function fadeIn(time, callback)
    if fadeTimer then Timer.cancel(fadeTimer) end

    fade = {
        height = push.getHeight() * 2,
        texture = util.newGradient("vertical", {0, 0, 0, 0}, {0, 0, 0},
                                   {0, 0, 0})
    }
    fade.y = -fade.height / 2
    fadeTimer = Timer.tween(time * 2, fade, {y = fade.height}, "linear",
                            function()
        fade.texture:release()
        fade = nil
        if callback then callback() end
    end)
end

isSwitchingState = false
function switchState(state, transition)
    if transition == nil then transition = true end

    isSwitchingState = true

    local function switch()
        Timer.clear()
        for _, o in pairs(Gamestate.current()) do
            if type(o) == "table" and o.destroy then o:destroy() end
        end
        paths.clearCache()
        Gamestate.switch(state)
        isSwitchingState = false
        collectgarbage()
    end

    if transition then
        fadeOut(0.7, function()
            switch()
            fadeIn(0.6)
        end)
    else
        switch()
    end
end

function love.run()
    local _, _, flags = love.window.getMode()
    love.FPScap, love.unfocusedFPScap = math.max(flags.refreshrate, 120), 8

    love.graphics.clear(0, 0, 0, 0, false, false)
    love.graphics.present()

    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end

    collectgarbage()
    collectgarbage("stop")

    local firstTime, fullGC = true, true
    return function()
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" and (not love.quit or not love.quit()) then
                    return a or 0
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        local dt, focused = love.timer and love.timer.step() or 0, firstTime or
                                not love.window or love.window.hasFocus()

        if focused then
            if love.update then love.update(dt) end

            if love.graphics and love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())
                if love.draw then love.draw() end

                local stats = love.graphics.getStats()
                love.graphics.printf("FPS: " ..
                                         math.min(love.timer.getFPS(),
                                                  love.FPScap) .. "\nGC MEM: " ..
                                         math.countbytes(collectgarbage("count")) ..
                                         "\nTEX MEM: " ..
                                         math.countbytes(stats.texturememory) ..
                                         "\nDRAWS: " .. stats.drawcalls, 6, 6,
                                     300, "left", 0)

                love.graphics.present()
            end
        end

        if love.timer then
            love.timer.sleep(1 /
                                 (focused and love.FPScap or
                                     love.unfocusedFPScap) - dt)
        end

        if focused then
            collectgarbage("step")
            fullGC = true
        elseif fullGC then
            collectgarbage()
            fullGC = false
        end

        firstTime = false
    end
end

function love.load()
    love.mouse.setVisible(false)

    local os = love.system.getOS()
    if os == "Android" or os == "iOS" then love.window.setFullscreen(true) end

    local dimensions = require "dimensions"
    push.setupScreen(dimensions.width, dimensions.height, {upscale = "normal"})

    switchState(TitleState(), false)
end

function love.resize(width, height)
    push.resize(width, height)
    Gamestate.resize(width, height)
end

function love.keypressed(...) controls:onKeyPress(...) end

function love.keyreleased(...) controls:onKeyRelease(...) end

function love.update(dt)
    dt = math.min(dt, 1 / 30)

    for _, o in pairs(Conductor.instances) do o:update(dt) end

    controls:update()
    Timer.update(dt)
    Gamestate.update(dt)
end

function love.draw()
    push.start()
    Gamestate.draw()
    if fade then
        love.graphics.draw(fade.texture, 0, fade.y, 0, push:getWidth(),
                           fade.height)
    end
    push.finish()
end

function love.focus(f)
    for _, o in pairs(Conductor.instances) do
        if not f then
            o.lastPause = o:isPaused()
            o:pause()
        else
            if not o.lastPause and not o:isFinished() then o:play() end
            o.lastPause = nil
        end
    end
end
