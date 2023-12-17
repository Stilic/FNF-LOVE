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
Mods = require "funkin.backend.mods"
ModCard = require "funkin.ui.modcard"

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

local consolas, real_fps = love.graphics.newFont('assets/fonts/consolas.ttf', 14), 0
function love.run()
    local _, _, modes = love.window.getMode()
    love.FPScap, love.unfocusedFPScap = math.max(modes.refreshrate, 60), 8
    love.showFPS = false
    love.autoPause = flags.InitialAutoFocus
    love.parallelUpdate = flags.InitialParallelUpdate

    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    collectgarbage()
    collectgarbage("step")

    local _stats, _update, _ram, _vram, _text
    local function draw()
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        love.draw()

        if love.showFPS then
            _stats, _update = love.graphics.getStats(), love.timer.getUpdateFPS()
            _ram, _vram = math.countbytes(collectgarbage("count") * 0x400), math.countbytes(_stats.texturememory)
            _text = "FPS: " .. (math.min(love.parallelUpdate and real_fps or _update, love.FPScap)) ..
                         (love.parallelUpdate and (" | UPDATE: " .. _update) or "") ..
                         "\nRAM: " .. _ram .. " | VRAM: " .. _vram ..
                         "\nDRAWS: " .. _stats.drawcalls

            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.printf(_text, consolas, 8, 8, 300, "left", 0)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(_text, consolas, 6, 6, 300, "left", 0)
        end

        love.graphics.present()
    end

    -- note:
    -- arithmetic like a + b - c would be the same as a - (c - b)
    -- but it really matters alot in context depending on what its used for computer calculation
    love.timer.step()

    local polledEvents, _defaultEvents = {}, {}
    local fpsUpdateFrequency, prevFpsUpdate, timeSinceLastFps, frames = 1, 0, 0, 0
    local firstTime, fullGC, focused, dt, real_dt = true, true, false, 0
    local nextclock, prevclock, clock, cap = 0, 0, 0
    return function()
        love.event.pump()
        table.merge(polledEvents, _defaultEvents)
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" and not love.quit() then
                return a or 0
            end
            _defaultEvents[name], polledEvents[name] = false, true
            love.handlers[name](a, b, c, d, e, f)
        end

        real_dt = love.timer.step()
        if not polledEvents.lowmemory and ((fullGC and not focused) or real_dt - dt > 0.04) then
            love.handlers.lowmemory()
            fullGC = false
            dt = dt + 0.04
        else
            fullGC = true
            dt = real_dt
        end

        focused = firstTime or love.window.hasFocus()
        cap = 1 / (focused and love.FPScap or love.unfocusedFPScap)

        if focused or not love.autoPause then
            love.update(dt)
            if love.graphics.isActive() then
                if love.parallelUpdate then
                    if clock + real_dt > nextclock then
                        draw()
                        nextclock = cap + clock
                        timeSinceLastFps, frames = clock - prevFpsUpdate, frames + 1
                        if timeSinceLastFps > fpsUpdateFrequency then
                            real_fps, frames = math.round(frames/timeSinceLastFps), 0
                            prevFpsUpdate = clock
                        end
                    end
                else
                    draw()
                end
            end
        end

        if firstTime then
            firstTime = false
        else
            collectgarbage("step")
        end

        if not love.parallelUpdate or not focused then
            love.timer.sleep(cap - real_dt)
            s()
        else
            love.timer.sleep(0.001 - (clock - prevclock))
        end

        -- using clock instead of love.timer.getTime() because it messes up parallelUpdate
        prevclock, clock = clock, os.clock()
    end
end

local _ogGetFPS = love.timer.getFPS

---@return number -- Returns the current draws FPS.
function love.timer.getDrawFPS()
    return love.parallelUpdate and real_fps or _ogGetFPS()
end

---@return number -- Returns the current updates FPS.
love.timer.getUpdateFPS = _ogGetFPS

---@return number -- Returns the current frames per second.
love.timer.getFPS = love.timer.getDrawFPS

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
    Mods.loadMods()

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
    controls:update()

    Timer.update(dt)
    game.update(dt)

    if love.system.getDevice() == "Desktop" then Discord.update() end
end

function love.draw() game.draw() end

function love.focus(f) game.focus(f) end

function love.quit()
    game.quit()
    Discord.shutdown()
end