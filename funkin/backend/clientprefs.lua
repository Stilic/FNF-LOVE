local ClientPrefs = {}

ClientPrefs.data = {
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

	pick_mods = {"key:6"},

	debug_1 = {"key:7"},
	debug_2 = {"key:8"},
}

function ClientPrefs.saveData()
	game.save.data.prefs = ClientPrefs.data
	game.save.data.controls = ClientPrefs.controls

	game.save.bind('funkin')
end

function ClientPrefs.loadData()
	game.save.init('funkin')

	pcall(table.merge, ClientPrefs.data, game.save.data.prefs)

	if game.save.data.prefs then
		love.FPScap = ClientPrefs.data.fps
	else
		ClientPrefs.data.fps = love.FPScap
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
