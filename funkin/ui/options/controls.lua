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

	{"volume_down",  "Volume -"},
	{"volume_up",    "Volume +"},
	{"volume_mute",  "Mute"},

	{"MISCELLANEOUS"},
	{"fullscreen",   "Fullscreen"},
	{"pick_mods",    "Mods"},
	{"asyncInput", "Asynchronous Input", "boolean", function()
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
Controls.binds = 2
Controls.titleWidth = 1 / 3

function Controls:onLeaveTab(id)
	if self.binds > 1 then
		for bind = 1, self.binds do
			local item = self.tab.items[id]
			if item and item.texts then
				local obj = item.texts[bind]
				if obj then obj.content = self:getOptionString(id, bind) end
			end
		end
	end
end

function Controls:onChangeSelection(id, prevID)
	if self.binds > 1 then
		for bind = 1, self.binds do
			local item = self.tab.items[prevID]
			if item and item.texts then
				local obj = item.texts[bind]
				if obj then obj.content = self:getOptionString(prevID, bind) end
			end
		end
	end
	self:changeBind(id, 0)
	self.curSelect = id
end

function Controls:getOptionString(id, bind)
	local option = self.settings[id]
	if option[1] == "asyncInput" then return Settings.getOptionString(self, id, 1) end
	local str = ClientPrefs.controls[option[1]][bind]
	return str and str:sub(5):capitalize() or "None"
end

function Controls:enterOption(id, optionsUI)
	local option = self.settings[id]
	if option[1] == "asyncInput" then
		self.curBind = 1
		return Settings.enterOption(self, id)
	end
	optionsUI.blockInput = true
	optionsUI.changingOption = false
	self.onBinding = true

	if not self.bg then
		self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
		self.bg:setScrollFactor()
		self.bg.alpha = 0.5

		self.waitInputTxt = Text(0, 0, "Rebinding...", paths.getFont("phantommuff.ttf", 40),
			{1, 1, 1}, "center", game.width)
		self.waitInputTxt:screenCenter('y')
		self.waitInputTxt:setScrollFactor()
	end
	optionsUI:add(self.bg)
	optionsUI:add(self.waitInputTxt)
end

function Controls:changeOption(id, add, optionsUI, bind)
	local option = self.settings[id]
	if option[1] == "asyncInput" then return Settings.changeOption(self, id, add, optionsUI, 1) end
	return false
end

function Controls:changeBind(id, add, dont)
	local option = self.settings[id]
	if option[1] ~= "asyncInput" then return Settings.changeBind(self, id, add) end
end

function Controls:update(dt, optionsUI)
	if not self.onBinding then return end

	if controls:pressed("back") then
		optionsUI:remove(self.bg)
		optionsUI:remove(self.waitInputTxt)
		optionsUI.blockInput = false
		self.onBinding = false

		return true
	end

	if self.onBinding and game.keys.loveInput then
		game.sound.play(paths.getSound('confirmMenu'))
		optionsUI:remove(self.bg)
		optionsUI:remove(self.waitInputTxt)
		optionsUI.blockInput = false
		self.onBinding = false

		local controlsTable = table.clone(ClientPrefs.controls)

		local id = self.curSelect
		local option = self.settings[id]
		local keyName = option[1]

		local newBind = "key:" .. game.keys.loveInput:lower()
		local secBind = self.curBind == 1 and 2 or 1
		local oldBind = controlsTable[keyName][self.curBind]

		controlsTable[keyName][self.curBind] = newBind

		if controlsTable[keyName][self.curBind] == controlsTable[keyName][secBind] then
			controlsTable[keyName][secBind] = oldBind
		end

		ClientPrefs.controls = table.clone(controlsTable)
		local config = {controls = table.clone(ClientPrefs.controls)}
		controls:reset(config)

		if self.binds > 1 then
			for bind = 1, self.binds do
				local item = self.tab.items[id]
				if item and item.texts then
					local obj = item.texts[bind]
					if obj then obj.content = self:getOptionString(id, bind) end
				end
			end
		end
		self:changeBind(id, 0)

		return true
	end
end

return Controls
