io.stdout:setvbuf("no")
require "loxel.lib.override"

Project = require "project"
flags = Project.flags

require "run"
require "loxel"

StatsCounter = require "loxel.system.statscounter"
if flags.ShowPrintsInScreen or love.system.getDevice() == "Mobile" then
	ScreenPrint = require "loxel.system.screenprint"
end

Timer = require "lib.timer"
Https = require "lib.https"

if love.system.getOS() == "Windows" then
	WindowDialogue = require "lib.windows.dialogue"
	WindowUtil = require "lib.windows.util"
end

paths = require "funkin.paths"
util = require "funkin.util"

ClientPrefs = require "funkin.backend.clientprefs"
Conductor = require "funkin.backend.conductor"
Discord = require "funkin.backend.discord"
Highscore = require "funkin.backend.highscore"
Mods = require "funkin.backend.mods"
Script = require "funkin.backend.script"
ScriptsHandler = require "funkin.backend.scriptshandler"
Throttle = require "funkin.backend.throttle"

HealthIcon = require "funkin.gameplay.ui.healthicon"
Note = require "funkin.gameplay.ui.note"
NoteSplash = require "funkin.gameplay.ui.notesplash"
Receptor = require "funkin.gameplay.ui.receptor"
BackgroundDancer = require "funkin.gameplay.backgrounddancer"
BackgroundGirls = require "funkin.gameplay.backgroundgirls"
Character = require "funkin.gameplay.character"
Stage = require "funkin.gameplay.stage"
TankmenBG = require "funkin.gameplay.tankmenbg"

Alphabet = require "funkin.ui.alphabet"
MenuCharacter = require "funkin.ui.menucharacter"
MenuItem = require "funkin.ui.menuitem"
ModCard = require "funkin.ui.modcard"
Options = require "funkin.ui.options"

TitleState = require "funkin.states.title"
MainMenuState = require "funkin.states.mainmenu"
ModsState = require "funkin.states.mods"
StoryMenuState = require "funkin.states.storymenu"
FreeplayState = require "funkin.states.freeplay"
PlayState = require "funkin.states.play"

ChartErrorSubstate = require "funkin.substates.charterror"
GameOverSubstate = require "funkin.substates.gameover"

CharacterEditor = require "funkin.states.editors.character"
ChartingState = require "funkin.states.editors.charting"

local SplashScreen = require "funkin.states.splash"

if WindowUtil then
	-- since love 12.0, windows no longer recreates for updateMode
	if love._version_major < 12 then
		local _ogUpdateMode = love.window.updateMode
		local includes = {"x", "y", "centered"}
		function love.window.updateMode(width, height, settings)
			local nuh, f = false, love.window.getFullscreen()
			if settings then
				for i, v in pairs(settings) do
					if not table.find(includes, i) and (i ~= "fullscreen" or v ~= f) then
						nuh = true
						break
					end
				end
			end

			if nuh then
				local s = _ogUpdateMode(width, height, settings)
				WindowUtil.setDarkMode(true)
				return s
			end

			if f then return false end

			local x, y, flags = love.window.getMode()
			local centered = true
			if settings and settings.centered ~= nil then centered = settings.centered end
			if centered then
				local width2, height2 = love.window.getDesktopDimensions(flags.display)
				x, y = (width2 - width) / 2, (height2 - height) / 2
			else
				x, y = settings and settings.x or x, settings and settings.y or y
			end

			WindowUtil.setWindowPosition(x, y, width, height)

			return true
		end
	end

	local _ogSetMode = love.window.setMode
	function love.window.setMode(...)
		_ogSetMode(...)
		WindowUtil.setDarkMode(true)
	end
end

function love.load()
	if WindowUtil then
		WindowUtil.setDarkMode(true)
	end

	if Project.bgColor then
		love.graphics.setBackgroundColor(Project.bgColor)
	end

	game.statsCounter = StatsCounter(6, 6,
		love.graphics.newFont('assets/fonts/consolas.ttf', 14), love.graphics.newFont('assets/fonts/consolas.ttf', 18))

	ClientPrefs.loadData()
	Mods.loadMods()
	Highscore.load()

	game.init(Project, SplashScreen)
	game.onPreStateSwitch = function(state)
		if paths and getmetatable(state) ~= getmetatable(game.getState()) then
			paths.clearCache()
		end
	end

	game:add(game.statsCounter)

	if ScreenPrint then
		ScreenPrint.init(love.graphics.getDimensions())
		game:add(ScreenPrint)
		
		local ogprint = print
		function print(...)
			local v = {...}
			for i = 1, #v do v[i] = tostring(v[i]) end
			ScreenPrint.new(table.concat(v, ", "))
			ogprint(...)
		end
	end

	Discord.init()
end

function love.resize(w, h) game.resize(w, h) end

function love.keypressed(key, ...)
	if Project.DEBUG_MODE and love.keyboard.isDown("lctrl", "rctrl") then
		if key == "f4" then error("force crash") end
		if key == "`" then return "restart" end
	end
	controls:onKeyPress(key, ...)
	game.keypressed(key, ...)
end

function love.keyreleased(...)
	controls:onKeyRelease(...)
	game.keyreleased(...)
end

function love.wheelmoved(...) game.wheelmoved(...) end

function love.mousemoved(...) game.mousemoved(...) end

function love.mousepressed(...) game.mousepressed(...) end

function love.mousereleased(...) game.mousereleased(...) end

function love.touchmoved(...) game.touchmoved(...) end

function love.touchpressed(...) game.touchpressed(...) end

function love.touchreleased(...) game.touchreleased(...) end

function love.textinput(text) game.textinput(text) end

function love.update(dt)
	controls:update()

	Throttle:update(dt)
	Timer.update(dt)
	game.update(dt)

	if love.system.getDevice() == "Desktop" then Discord.update() end
	if controls:pressed("fullscreen") then love.window.setFullscreen(not love.window.getFullscreen()) end
end

function love.draw()
	game.draw()
end

function love.focus(f) game.focus(f) end

function love.fullscreen(f, t)
	ClientPrefs.data.fullscreen = f
	game.fullscreen(f)
end

function love.quit()
	ClientPrefs.saveData()
	game.quit()
	Discord.shutdown()
end
