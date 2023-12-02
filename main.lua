io.stdout:setvbuf("no")

Application = require "project"
flags = Application.flags

require "loxel"

Timer = require "lib.timer"

-- WindowDialogue = require "lib.windows.dialogue"
paths = require "funkin.paths"
util = require "funkin.util"

Highscore = require "funkin.backend.highscore"

ClientPrefs = require "funkin.backend.clientprefs"
Script = require "funkin.backend.script"
ScriptsHandler = require "funkin.backend.scriptshandler"
Conductor = require "funkin.backend.conductor"
Note = require "funkin.gameplay.ui.note"
NoteSplash = require "funkin.gameplay.ui.notesplash"
Receptor = require "funkin.gameplay.ui.receptor"
Stage = require "funkin.gameplay.stage"
Character = require "funkin.gameplay.character"
MenuCharacter = require "funkin.ui.menucharacter"
MenuItem = require "funkin.ui.menuitem"
Alphabet = require "funkin.ui.alphabet"
HealthIcon = require "funkin.gameplay.ui.healthicon"
BackgroundGirls = require "funkin.gameplay.backgroundgirls"
ParallaxImage = require "loxel.effects.parallax"

TitleState = require "funkin.states.title"
MainMenuState = require "funkin.states.mainmenu"
StoryMenuState = require "funkin.states.storymenu"
FreeplayState = require "funkin.states.freeplay"
PlayState = require "funkin.states.play"

GameOverSubstate = require "funkin.substates.gameover"

OptionsState = require "funkin.states.options.options"

CharacterEditor = require "funkin.states.editors.character"
ChartingState = require "funkin.states.editors.charting"

local SplashScreen = require "funkin.states.splash"

require "errorhandler"

function love.run()
    local _, _, flags = love.window.getMode()
    love.FPScap, love.unfocusedFPScap = math.max(flags.refreshrate, 120), 8

    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end

    collectgarbage()
    collectgarbage("step")

    if not love.quit then love.quit = function()end end

    local firstTime, fullGC, focused, dt = true, true, false, 0
    return function()
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" and (not love.quit()) then
                return a or 0
            end
            love.handlers[name](a, b, c, d, e, f)
        end

        focused = firstTime or love.window.hasFocus()
        dt = love.timer.step() or 0

        if focused then
            love.update(dt)

            if love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())
                love.draw()

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

        love.timer.sleep(1 / (focused and love.FPScap or love.unfocusedFPScap) - dt)

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

-- Gets the current device
---@return string -- The current device. 'Desktop' or 'Mobile'
function love.system.getDevice()
	local os = love.system.getOS()
    if os == "Android" or os == "iOS" then
        return "Mobile"
    elseif os == "OS X" or os == "Windows" or os == "Linux" then
        return "Desktop"
    end
    return "Unknown"
end

function love.load()
    if Application.bgColor then
        love.graphics.setBackgroundColor(Application.bgColor)
    end

    -- for the joystick, i'll remake it later
    controls = (require "lib.baton").new({
        controls = table.clone(ClientPrefs.controls)
    })

    game.init(Application, SplashScreen)

    if love.system.getDevice() == "Desktop" then 
    	Discord = require "funkin.backend.discord"
    	Discord.init()
    else
    	local function foo() end
    	Discord = {
    		changePresence = foo
    	}
    end
end

function love.resize(w, h) game.resize(w, h) end

function love.keypressed(...)
    controls:onKeyPress(...)
    game.keypressed(...)
end
function love.keyreleased(...)
    controls:onKeyRelease(...)
    game.keyreleased(...)
end
function love.textinput(text) game.textinput(text) end

function love.wheelmoved(x, y) game.wheelmoved(x, y) end
function love.mousemoved(x, y) game.mousemoved(x, y) end
function love.mousepressed(x, y, button) game.mousepressed(x, y, button) end
function love.mousereleased(x, y, button) game.mousereleased(x, y, button) end

function love.update(dt)
    dt = math.min(dt, 1 / 30) -- temporary workaround until we can detect when freezes started smh

    Timer.update(dt)
    controls:update()

    game.update(dt)

    if love.system.getDevice() == "Desktop" then Discord.update() end
end

function love.draw() game.draw() end

function love.focus(f) game.focus(f) end

function love.quit() Discord.shutdown() end