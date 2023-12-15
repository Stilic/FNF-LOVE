io.stdout:setvbuf("no")
print("")

Project = require "project"
flags = Project.flags

require "loxel"

Timer = require "lib.timer"

WindowDialogue = require "lib.windows.dialogue"
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
BackgroundDancer = require "funkin.gameplay.backgrounddancer"
BackgroundGirls = require "funkin.gameplay.backgroundgirls"
TankmenBG = require "funkin.gameplay.tankmenbg"
ParallaxImage = require "loxel.effects.parallax"

ModsState = require "funkin.states.mods"
TitleState = require "funkin.states.title"
MainMenuState = require "funkin.states.mainmenu"
StoryMenuState = require "funkin.states.storymenu"
FreeplayState = require "funkin.states.freeplay"
PlayState = require "funkin.states.play"

ChartErrorSubstate = require "funkin.substates.charterror"
GameOverSubstate = require "funkin.substates.gameover"

OptionsState = require "funkin.states.options.options"

CharacterEditor = require "funkin.states.editors.character"
ChartingState = require "funkin.states.editors.charting"

local SplashScreen = require "funkin.states.splash"

require "errorhandler"

local consolas = love.graphics.newFont('assets/fonts/consolas.ttf', 14)
function love.run()
    local _, _, modes = love.window.getMode()
    love.FPScap, love.unfocusedFPScap = math.max(modes.refreshrate, 120), 8
    love.showFPS = false
    love.autoPause = flags.InitialAutoFocus

    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end

    collectgarbage()
    collectgarbage("step")

    if not love.quit then love.quit = function()end end

    local function draw()
        if not love.graphics.isActive() then return end
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        love.draw()

        if love.showFPS then
            local stats = love.graphics.getStats()
            local fps = math.min(love.timer.getFPS(), love.FPScap)
            local vram = math.countbytes(stats.texturememory)
            local text = "FPS: " .. fps ..
                         "\nVRAM: " .. vram ..
                         "\nDRAWS: " .. stats.drawcalls

            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.printf(text, consolas, 8, 8, 300, "left", 0)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(text, consolas, 6, 6, 300, "left", 0)
        end

        love.graphics.present()
    end

    local parallelUpdate = flags.ParallelUpdate
    local firstTime, fullGC, focused, dt = true, true, false, 0
    local nextclock, clock, cap = 0
    return function()
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" and (not love.quit()) then
                return a or 0
            end
            love.handlers[name](a, b, c, d, e, f)
        end

        focused = firstTime or love.window.hasFocus()
        cap = 1 / (focused and love.FPScap or love.unfocusedFPScap)

        dt = dt + math.min((love.timer.step() or 0) - dt, 0.04)

        if focused or not love.autoPause then
            love.update(dt)
            if parallelUpdate then
                clock = os.clock()
                if clock > nextclock then
                    draw()
                    nextclock = cap + clock
                end
            else
                draw()
            end
        end

        if focused then
            collectgarbage("step")
            fullGC = true
            firstTime = false
        elseif fullGC then
            collectgarbage()
            fullGC = false
        end

        if not parallelUpdate then
            love.timer.sleep(cap - dt)
        end
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
    if Project.bgColor then
        love.graphics.setBackgroundColor(Project.bgColor)
    end

    -- for the joystick, i'll remake it later
    game.save.init('funkin')
    ClientPrefs.loadData()

    Highscore.load()

    game.init(Project, SplashScreen)

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
    Timer.update(dt)
    controls:update()

    game.update(dt)

    if love.system.getDevice() == "Desktop" then Discord.update() end
end

function love.draw() game.draw() end

function love.focus(f) game.focus(f) end

function love.quit()
    game.quit()
    Discord.shutdown()
end