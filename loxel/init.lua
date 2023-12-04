require "loxel.lib.override"

game = {}
if flags == nil then flags = {} end

Classic = require "loxel.lib.classic"
local Gamestate = require "loxel.lib.gamestate"

Basic = require "loxel.basic"
Object = require "loxel.object"
Sound = require "loxel.sound"
Graphic = require "loxel.graphic"
Sprite = require "loxel.sprite"
Camera = require "loxel.camera"
Text = require "loxel.text"
Bar = require "loxel.ui.bar"
Group = require "loxel.group.group"
SpriteGroup = require "loxel.group.spritegroup"
State = require "loxel.state"
Substate = require "loxel.substate"
Flicker = require "loxel.effects.flicker"
Color = require "loxel.util.color"

Keyboard = require "loxel.input.keyboard"
Mouse = require "loxel.input.mouse"
ui = {
    UIButton = require "loxel.ui.button",
    UICheckbox = require "loxel.ui.checkbox",
    UIDropDown = require "loxel.ui.dropdown",
    UIGrid = require "loxel.ui.grid",
    UIInputTextBox = require "loxel.ui.inputtextbox",
    UINumericStepper = require "loxel.ui.numericstepper",
    UITabMenu = require "loxel.ui.tabmenu",
    UISlider = require "loxel.ui.slider"
}

game.cameras = require "loxel.managers.cameramanager"
game.sound = require "loxel.managers.soundmanager"
game.save = require "loxel.util.save"

local fade
local function fadeOut(time, callback)
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
local function fadeIn(time, callback)
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

local requestedState, skipTransition = nil, false
game.isSwitchingState = false
function game.switchState(state, skipTrans)
    requestedState = state

    if skipTrans == nil then
        skipTransition = false
    else
        skipTransition = skipTrans
    end
end
function game.resetState(skipTrans, ...)
    game.switchState(getmetatable(Gamestate.stack[1])(...), skipTrans)
end
function game.getState() return Gamestate.current() end

function game.init(app, state)
    game.width = app.width
    game.height = app.height
    Camera.__init(love.graphics.newCanvas(app.width, app.height))

    game.save.init('funkin')
    ClientPrefs.loadData()

    love.mouse.setVisible(false)

    local os = love.system.getOS()
    if os == "Android" or os == "iOS" then love.window.setFullscreen(true) end

    game.cameras.reset()

    Gamestate.switch(state())
end

local function callUIInput(func, ...)
    for _, o in ipairs(ui.UIInputTextBox.instances) do
        if o[func] then o[func](o, ...) end
    end
    for _, o in ipairs(ui.UINumericStepper.instances) do
        if o[func] then o[func](o, ...) end
    end
end
function game.keypressed(...)
    Keyboard.onPressed(...)
    callUIInput('keypressed', ...)
end
function game.keyreleased(...)
    Keyboard.onReleased(...)
    callUIInput('keyreleased', ...)
end
function game.textinput(text) callUIInput('textinput', text) end

function game.wheelmoved(x, y) Mouse.wheel = y end
function game.mousemoved(x, y) Mouse.onMoved(x, y) end
function game.mousepressed(x, y, button) Mouse.onPressed(button) end
function game.mousereleased(x, y, button) Mouse.onReleased(button) end

local function switch(state)
    Timer.clear()

    game.cameras.reset()
    game.sound.destroy()

    for _, s in ipairs(Gamestate.stack) do
        for _, o in ipairs(s.members) do
            if type(o) == "table" and o.destroy then o:destroy() end
        end
        if s.substate then
            Gamestate.pop(table.find(Gamestate.stack, s.substate))
            s.substate = nil
        end
    end

    paths.clearCache()

    Gamestate.switch(state)
    game.isSwitchingState = false

    collectgarbage()
end
function game.update(dt)
    if requestedState ~= nil then
        game.isSwitchingState = true
        if not skipTransition then
            local state = requestedState
            fadeOut(0.7, function()
                switch(state)
                fadeIn(0.6)
            end)
        else
            switch(requestedState)
        end
        requestedState = nil
    end

    for _, o in ipairs(Flicker.instances) do o:update(dt) end
    game.cameras.update(dt)
    game.sound.update()

    if not game.isSwitchingState then Gamestate.update(dt) end

    Keyboard.update()
    Mouse.update()
end
function game.draw()
    Gamestate.draw()
    if fade then
        table.insert(game.cameras.list[#game.cameras.list].__renderQueue,
                     fade.draw)
    end
    for _, c in ipairs(game.cameras.list) do c:draw() end
end

function game.resize(w, h) Gamestate.resize(w, h) end
function game.focus(f)
    game.sound.onFocus(f)
    Gamestate.focus(f)
end
function game.quit() ClientPrefs.saveData() end
