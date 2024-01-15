local Settings = require "funkin.ui.options.settings"
local Gameplay = Settings:base("Gameplay", {
	{"NOTES"},
	{"downScroll",   "Down Scroll", "boolean"},
	{"middleScroll", "Middle Scroll", "boolean"},
	{"noteSplash",   "Note Splash", "boolean"},
	{"botplayMode",  "Botplay", "boolean"}, -- this shouldnt be here.

	{"MISCELLANEOUS"},
	{"songOffset",   "Song Offset", "number"},
	{"pauseMusic",   "Pause Music", "string", {"railways", "breakfast"}},
	{"timeType",     "Song Time Type", "string", {"left", "elapsed"}}
})

return Gameplay