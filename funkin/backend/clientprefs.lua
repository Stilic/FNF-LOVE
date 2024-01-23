local ClientPrefs = {}

ClientPrefs.data = {
	-- controls
	asyncInput = false,

	-- gameplay
	downScroll = false,
	middleScroll = false,
	noteSplash = true,
	pauseMusic = 'railways',
	botplayMode = false,
	timeType = 'left',
	songOffset = 0,

	-- display
	fps = 0,
	showFps = false,
	antialiasing = true,
	lowQuality = false,
	shader = true,
	fullscreen = false,
	resolution = 1,
}

ClientPrefs.controls = {
	ui_left = {"key:a", "key:left"},
	ui_down = {"key:s", "key:down"},
	ui_up = {"key:w", "key:up"},
	ui_right = {"key:d", "key:right"},

	note_left = {"key:d", "key:left"},
	note_down = {"key:f", "key:down"},
	note_up = {"key:j", "key:up"},
	note_right = {"key:k", "key:right"},

	accept = {"key:space", "key:return"},
	back = {"key:backspace", "key:escape"},
	pause = {"key:return", "key:escape"},
	reset = {"key:r"},

	fullscreen = {"key:f11"},
	pick_mods = {"key:6"},

	debug_1 = {"key:7"},
	debug_2 = {"key:8"},
}

function ClientPrefs.saveData()
	ClientPrefs.data.fullscreen = love.window.getFullscreen()

	game.save.data.prefs = ClientPrefs.data
	game.save.data.controls = ClientPrefs.controls

	game.save.bind('funkin')
end

function ClientPrefs.loadData()
	game.save.init('funkin')

	pcall(table.merge, ClientPrefs.data, game.save.data.prefs)

	if game.save.data.prefs then
		love.FPScap = ClientPrefs.data.fps
		love.parallelUpdate = ClientPrefs.data.parallelUpdate
		love.asyncInput = ClientPrefs.data.asyncInput

		local res = ClientPrefs.data.resolution
		love.window.updateMode(Project.width * res, Project.height * res, {
			fullscreen = ClientPrefs.data.fullscreen
		})
	else
		ClientPrefs.data.fps = love.FPScap
		ClientPrefs.data.parallelUpdate = love.parallelUpdate
		ClientPrefs.data.resolution = love.graphics.getFixedScale()
	end

	love.showFPS = ClientPrefs.data.showFps
	Object.defaultAntialiasing = ClientPrefs.data.antialiasing

	pcall(table.merge, ClientPrefs.controls, game.save.data.controls)

	local config = {controls = table.clone(ClientPrefs.controls)}
	if controls == nil then
		controls = (require "lib.baton").new(config)
	else
		controls:reset(config)
	end
end

return ClientPrefs
