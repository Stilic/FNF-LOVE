local Settings = require "funkin.ui.options.settings"

local function percentvalue(value) return value .. "%" end
local data = {
	{"GENERAL"},
	{"autoPause", "Auto Pause On Lost Focus", "boolean", function()
		local value = not ClientPrefs.data.autoPause
		ClientPrefs.data.autoPause = value
		love.autoPause = value
	end},
	{"backgroundDim", "Background Dim", "number", function(add)
		local value = math.clamp(ClientPrefs.data.backgroundDim + add, 0, 100)
		ClientPrefs.data.backgroundDim = value
	end, percentvalue},
	{"notesBelowHUD", "Notes Below HUD", "boolean"},
	{"downScroll",   "Down Scroll",   "boolean"},
	{"middleScroll", "Middle Scroll", "boolean"},
	{"ghostTap", "Ghost Tap", "boolean"},
	{"noteSplash",   "Note Splash",   "boolean"},
	{"botplayMode",  "Botplay",       "boolean"},
	{"playback", "Playback", "number", function(add)
		local value = math.clamp(ClientPrefs.data.playback + (add * 0.05), 0.1, 5)
		ClientPrefs.data.playback = value
	end, function(value) return "x" .. value end},
	{"timeType",   "Song Time Type", "string", {"left", "elapsed"}},
	{"gameOverInfos", "Show game infos in Game Over", "boolean"},

	{"AUDIO"},
	{"pauseMusic", "Pause Music",    "string", {"railways", "breakfast"}},
	{"hitSound", "Hit Sound", "number", function(add)
		local value = math.clamp(ClientPrefs.data.hitSound + add, 0, 100)
		ClientPrefs.data.hitSound = value

		game.sound.play(paths.getSound('hitsound'), value / 100)
		return nil, true
	end, percentvalue},
	{"menuMusicVolume", "Menu Music Volume", "number", function(add)
		local value = math.clamp(ClientPrefs.data.menuMusicVolume + add, 0, 100)
		ClientPrefs.data.menuMusicVolume = value
	end, percentvalue},
	{"musicVolume", "Music Volume", "number", function(add)
		local value = math.clamp(ClientPrefs.data.musicVolume + add, 0, 100)
		ClientPrefs.data.musicVolume = value
	end, percentvalue},
	{"vocalVolume", "Vocal Volume", "number", function(add)
		local value = math.clamp(ClientPrefs.data.vocalVolume + add, 0, 100)
		ClientPrefs.data.vocalVolume = value
	end, percentvalue},
	{"sfxVolume", "SFX Volume", "number", function(add)
		local value = math.clamp(ClientPrefs.data.sfxVolume + add, 0, 100)
		ClientPrefs.data.sfxVolume = value
	end, percentvalue},
	{"songOffset", "Song Offset",    "number"},
	{"calibration", "Calibrate", function(optionsUI)
		if optionsUI.aboutToGoToCalibration then return end
		game.sound.play(paths.getSound('scrollMenu'))
		optionsUI.aboutToGoToCalibration = true
		optionsUI.changingOption = false
	end}
}

local Gameplay = Settings:base("Gameplay", data)

function Gameplay:update(dt, optionsUI)
	if optionsUI.aboutToGoToCalibration and not self.wow then
		if self.crateThing then
			if controls:pressed("back") then
				game.sound.play(paths.getSound('cancelMenu'))

				optionsUI:remove(self.bg)
				optionsUI:remove(self.waitInputTxt)
				optionsUI:remove(self.waitInputTxt2)

				optionsUI.blockInput = false
				optionsUI.aboutToGoToCalibration = nil
				self.crateThing = false

				return true
			elseif controls:pressed('accept') then
				game.getState().transOut = CalibrationState.transOut
				game.switchState(CalibrationState())
				self.wow = true

				return true
			end
		else
			if not self.bg then
				self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
				self.bg:setScrollFactor()
				self.bg.alpha = 0.5

				self.waitInputTxt = Text(0, 0, "Are you sure you want to enter Calibration?", paths.getFont("phantommuff.ttf", 40),
					{1, 1, 1}, "center", game.width)
				self.waitInputTxt:screenCenter('y')
				self.waitInputTxt:setScrollFactor()
				self.waitInputTxt.y = self.waitInputTxt.y - 40

				self.waitInputTxt2 = Text(0, 0, "Press Accept key to Continue, Press Escape key to Nevermind i think", paths.getFont("phantommuff.ttf", 24),
					{1, 1, 1}, "center", game.width)
				self.waitInputTxt2:screenCenter('y')
				self.waitInputTxt2:setScrollFactor()
				self.waitInputTxt2.y = self.waitInputTxt2.y + 40
			end
			optionsUI:add(self.bg)
			optionsUI:add(self.waitInputTxt)
			optionsUI:add(self.waitInputTxt2)
			self.crateThing = true
		end
	end
end

return Gameplay
