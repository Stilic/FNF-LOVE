local Settings = require "funkin.ui.options.settings"
local data = {
	{"NOTES"},
	{"downScroll",   "Down Scroll",    "boolean"},
	{"middleScroll", "Middle Scroll",  "boolean"},
	{"noteSplash",   "Note Splash",    "boolean"},
	{"botplayMode",  "Botplay",        "boolean"}, -- this shouldnt be here.

	{"MISCELLANEOUS"},
	{"songOffset",   "Song Offset",    "number"},
	{"pauseMusic",   "Pause Music",    "string", {"railways", "breakfast"}},
	{"timeType",     "Song Time Type", "string", {"left", "elapsed"}},
	{"asyncInput",   "Asynchronous Input", "boolean", function()
		love.asyncInput = not ClientPrefs.data.asyncInput
		ClientPrefs.data.asyncInput = love.asyncInput
	end}
}
if love.system.getDevice() ~= "Mobile" then
	for _, v in pairs(data) do
		if v[1] == "asyncInput" then
			table.delete(data, v)
			break
		end
	end
end

local Gameplay = Settings:base("Gameplay", data)
return Gameplay
