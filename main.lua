io.stdout:setvbuf("no")

require "lib.override"
require "loxel.init"

Timer = require "lib.timer"

paths = require "funkin.paths"
util = require "funkin.util"

Script = require "funkin.backend.script"
Conductor = require "funkin.backend.conductor"
Graphic = require "funkin.ui.graphic"
Note = require "funkin.gameplay.ui.note"
Receptor = require "funkin.gameplay.ui.receptor"
Stage = require "funkin.gameplay.stage"
Character = require "funkin.gameplay.character"
Alphabet = require "funkin.ui.alphabet"
HealthIcon = require "funkin.gameplay.ui.healthicon"
BackgroundGirls = require "funkin.gameplay.backgroundgirls"

TitleState = require "funkin.states.title"
MainMenuState = require "funkin.states.mainmenu"
FreeplayState = require "funkin.states.freeplay"
PlayState = require "funkin.states.play"

ChartingState = require "funkin.editors.charting"

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
        reset = {"key:r", "button:leftstick"},
        debug1 = {"key:7"}
    },
    joystick = love.joystick.getJoysticks()[1]
})

local fade
function fadeOut(time, callback)
    if fade and fade.timer then Timer.cancel(fade.timer) end

    fade = {
        height = game.height * 2,
        texture = util.newGradient("vertical", {0, 0, 0}, {0, 0, 0},
                                   {0, 0, 0, 0})
    }
    fade.y = -fade.height
    fade.timer = Timer.tween(time, fade, {y = 0}, "linear", function()
        fade.texture:release()
        fade = nil
        if callback then callback() end
    end)
    fade.draw = function()
        love.graphics.draw(fade.texture, 0, fade.y, 0, game.width, fade.height)
    end
end
function fadeIn(time, callback)
    if fade and fade.timer then Timer.cancel(fade.timer) end

    fade = {
        height = game.height * 2,
        texture = util.newGradient("vertical", {0, 0, 0, 0}, {0, 0, 0},
                                   {0, 0, 0})
    }
    fade.y = -fade.height / 2
    fade.timer = Timer.tween(time * 2, fade, {y = fade.height}, "linear",
                             function()
        fade.texture:release()
        fade = nil
        if callback then callback() end
    end)
    fade.draw = function()
        love.graphics.draw(fade.texture, 0, fade.y, 0, game.width, fade.height)
    end
end

isSwitchingState = false
function switchState(state, transition)
    if transition == nil then transition = true end

    isSwitchingState = true

    local function switch()
        Timer.clear()

        game.cameras.reset()
        game.sound.destroy()

        for _, s in ipairs(Gamestate.stack) do
            for _, o in ipairs(s.members) do
                if type(o) == "table" and o.destroy then
                    o:destroy()
                end
            end
            if s.subState then
                Gamestate.pop(table.find(Gamestate.stack, s.subState))
                s.subState = nil
            end
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
function resetState(transition, ...)
    switchState(getmetatable(Gamestate.stack[1])(...), transition)
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
                                                  love.FPScap) .. "\nVRAM: " ..
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

    Gamestate.switch(TitleState())
end

function love.resize(w, h) Gamestate.resize(w, h) end

local function callUIInput(func, ...)
    for _, o in ipairs(ui.UIInputTextBox.instances) do
        if o[func] then o[func](o, ...) end
    end
    for _, o in ipairs(ui.UINumericStepper.instances) do
        if o[func] then o[func](o, ...) end
    end
end
function love.keypressed(...)
    controls:onKeyPress(...)
    Keyboard.onPressed(...)
    callUIInput('keypressed', ...)
end
function love.keyreleased(...)
    controls:onKeyRelease(...)
    Keyboard.onReleased(...)
    callUIInput('keyreleased', ...)
end
function love.textinput(text) callUIInput('textinput', text) end

function love.wheelmoved(x, y) Mouse.wheel = y end
function love.mousemoved(x, y) Mouse.onMoved(x, y) end
function love.mousepressed(x, y, button) Mouse.onPressed(button) end
function love.mousereleased(x, y, button) Mouse.onReleased(button) end

function love.update(dt)
    dt = math.min(dt, 1 / 30)

    for _, o in ipairs(Flicker.instances) do o:update(dt) end
    game.cameras.update(dt)
    game.sound.update()

    Timer.update(dt)
    controls:update()

    if not isSwitchingState then Gamestate.update(dt) end

    Keyboard.update()
    Mouse.update()
end

function love.draw()
    Gamestate.draw()
    if fade then
        table.insert(game.cameras.list[#game.cameras.list].__renderQueue,
                     fade.draw)
    end
    for _, c in ipairs(game.cameras.list) do c:draw() end
end

function love.focus(f)
    game.sound.onFocus(f)
    Gamestate.focus(f)
end
