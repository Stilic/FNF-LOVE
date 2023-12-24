io.stdout:setvbuf("no")

Project = require "project"
flags = Project.flags

require "run"
require "loxel"

Timer = require "lib.timer"
Https = require "lib.https"

paths = require "funkin.paths"
util = require "funkin.util"

Discord = require "funkin.backend.discord"
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

if love.system.getOS() == "Windows" then
	WindowDialogue = require "lib.windows.dialogue"
	WindowUtil = require "lib.windows.util"
end

local SplashScreen = require "funkin.states.splash"

function love.load()
	if WindowUtil then
		WindowUtil.setDarkMode(Project.title, true)
	end

	if Project.bgColor then
		love.graphics.setBackgroundColor(Project.bgColor)
	end

	game.save.init('funkin')
	ClientPrefs.loadData()
	Mods.loadMods()

	Highscore.load()

	game.init(Project, SplashScreen)
	Discord.init()
end

function love.resize(w, h) game.resize(w, h) end

function love.keypressed(key, ...)
	if love.keyboard.isDown("lctrl", "rctrl") then
		if key == "f4" then error("force crash") end
	end
	controls:onKeyPress(key, ...)
	game.keypressed(key, ...)
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

function love.touchmoved(id, x, y) game.touchmoved(id, x, y) end

function love.touchpressed(id, x, y) game.touchpressed(id, x, y) end

function love.touchreleased(id, x, y) game.touchreleased(id, x, y) end

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
