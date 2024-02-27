local Settings = require "funkin.ui.options.settings"

local data = {
	{"NOTES"},
	{"downScroll",   "Down Scroll",   "boolean"},
	{"middleScroll", "Middle Scroll", "boolean"},
	{"noteSplash",   "Note Splash",   "boolean"},
	{"botplayMode",  "Botplay",       "boolean"}, -- this shouldnt be here.

	{"MISCELLANEOUS"},
	{"backgroundDim", "Background Dim", "number", function(add)
		local value = ClientPrefs.data.backgroundDim
		value = value + add
		if value > 100 then
			value = 100
		elseif value < 0 then
			value = 0
		end
		ClientPrefs.data.backgroundDim = value
	end, function(value)
		return tostring(value) .. "%"
	end},
	{"playback", "Playback", "number", function(add)
		local value = ClientPrefs.data.playback
		value = value + (add > 0 and 0.05 or -0.05)
		if value > 2 then
			value = 2
		elseif value < 0.2 then
			value = 0.2
		end
		ClientPrefs.data.playback = value
	end, function(value)
		return "x" .. tostring(value)
	end},
	{"songOffset", "Song Offset",    "number"},
	{"pauseMusic", "Pause Music",    "string", {"railways", "breakfast"}},
	{"timeType",   "Song Time Type", "string", {"left", "elapsed"}}
}

local Gameplay = Settings:base("Gameplay", data)
return Gameplay
