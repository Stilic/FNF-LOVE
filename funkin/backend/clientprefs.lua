local ClientPrefs = {}

ClientPrefs.data = {
	-- gameplay
	downScroll = false,
	noteSplash = true,
	pauseMusic = 'railways',
	botplayMode = false,
	songOffset = 0,
	
	-- display
	fps = 120,
	antialiasing = true,
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

	debug_1 = {"key:7"},
	debug_2 = {"key:8"}
}

return ClientPrefs
