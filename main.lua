io.stdout:setvbuf("no")

require "lib.override"

Object = require "lib.classic"
Timer = require "lib.timer"
Gamestate = require "lib.gamestate"

Camera = require "game.camera"
Sprite = require "game.sprite"
Sound = require "game.sound"
Text = require "game.text"
Bar = require "game.bar"
Group = require "game.group"
SpriteGroup = require 'game.spritegroup'
State = require "game.state"
SubState = require "game.substate"
Flicker = require "game.flicker"

paths = require "game.paths"
util = require "game.util"

Script = require "game.script"

Conductor = require "game.conductor"
Note = require "game.gameplay.ui.note"
Receptor = require "game.gameplay.ui.receptor"
HealthIcon = require "game.gameplay.ui.healthicon"
Stage = require "game.gameplay.stage"
Character = require "game.gameplay.character"

Alphabet = require "game.alphabet"
BackgroundGirls = require "game.gameplay.backgroundgirls"

TitleState = require "game.states.title"
MainMenuState = require "game.states.mainmenu"
FreeplayState = require "game.states.freeplay"
PlayState = require "game.states.play"

ChartingState = require "game.editors.charting"

game = {
    camera = nil,
    cameras = require "game.cameramanager",
    sound = require "game.soundmanager"
}

Keyboard = require "game.input.keyboard"
Mouse = require "game.input.mouse"

ui = {
    UIButton = require "game.ui.button",
    UICheckbox = require "game.ui.checkbox",
    UIDropDown = require "game.ui.dropdown",
    UIGrid = require "game.ui.grid",
    UIInputTextBox = require "game.ui.inputtextbox",
    UINumericStepper = require "game.ui.numericstepper",
    UITabMenu = require "game.ui.tabmenu",
    UIText = require "game.ui.text"
}

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

    local dimensions = require "dimensions"
    game.width, game.height = dimensions.width, dimensions.height

    game.cameras.reset()

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
