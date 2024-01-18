local Settings = require "funkin.ui.options.settings"

local data = {
	{"NOTES"},
	{"note_left",    "Left"},
	{"note_down",    "Down"},
	{"note_up",      "Up"},
	{"note_right",   "Right"},

	{"UI"},
	{"ui_left",      "Left"},
	{"ui_down",      "Down"},
	{"ui_up",        "Up"},
	{"ui_right",     "Right"},
	{"reset",        "Reset"},
	{"accept",       "Accept"},
	{"back",         "Back"},
	{"pause",        "Pause"},

	{"MISCELLANEOUS"},
	{"fullscreen",   "Fullscreen"},
	{"pick_mods",    "Mods"},
	{"asyncInput",   "Asynchronous Input", "boolean", function()
		love.asyncInput = not ClientPrefs.data.asyncInput
		ClientPrefs.data.asyncInput = love.asyncInput
	end, nil, 0.5}
}
if Project.DEBUG_MODE then
	table.insert(data, {"DEBUG"})
	table.insert(data, {"debug_1", "Charting"})
	table.insert(data, {"debug_2", "Character"})
end

local Controls = Settings:base("Controls", data)
Controls.binds = 4
Controls.titleWidth = 1 / 5

function Controls:getOptionString(id, bind)
	local option = self.settings[id]
	if option[1] == "asyncInput" then return Settings.getOptionString(self, id, bind) end
	local str = ClientPrefs.controls[option[1]][bind]
	return str and str:sub(5):capitalize() or "None"
end

function Controls:changeOption(id, add, optionsUI, bind)
	local option = self.settings[id]
	if option[1] == "asyncInput" then return Settings.changeOption(self, id, add, optionsUI, bind) end
	return false
end

--[[
function Controls:acceptOption(id, optionsUI, bind)
	optionsUI.blockInput = true
	self.onBinding = true

	if not self.bg then
		self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
		self.bg:setScrollFactor()
		self.bg.alpha = 0.5
	end
	optionsUI:add(self.bg)

	return false
end

function Controls:update(dt, optionsUI)
	if not self.onBinding then return end
	if controls:pressed("back") then
		optionsUI:remove(self.bg)
		optionsUI.blockInput = false
		self.onBinding = false
		return
	end
end
]]

return Controls
