local Gameplay = {}

local optionsVar = {
	{'downScroll',   'Down Scroll',    false, 'boolean'},
	{'middleScroll', 'Middle Scroll',  false, 'boolean'},
	{'noteSplash',   'Note Splash',    false, 'boolean'},
	{'pauseMusic',   'Pause Music',    false, 'string', {'railways', 'breakfast'}},
	{'botplayMode',  'Botplay',        false, 'boolean'},
	{'timeType',     'Song Time Type', false, 'string', {'left', 'elapsed'}},
	{'songOffset',   'Song Offset',    false, 'number', {0, 999}},
}

local curSelected = 1
local stringSelected = 1

function Gameplay.add(options)
	local gameplayTab = Group()
	gameplayTab.name = 'Gameplay'

	for i, daOption in ipairs(optionsVar) do
		local daGroup = Group()

		local yPos = (i * 45) + 80
		local title = Text(145, yPos, daOption[2],
			paths.getFont('phantommuff.ttf', 30), {1, 1, 1})
		daGroup:add(title)

		local realvalue = ClientPrefs.data[daOption[1]]
		if type(realvalue) == "boolean" then
			if realvalue then
				realvalue = "enabled"
			else
				realvalue = "disabled"
			end
		end
		local value = daOption[3] and '< ' .. tostring(realvalue)
			.. ' >' or tostring(realvalue)
		local valueTxt = Text((game.width / 2) + 10, yPos, value,
			paths.getFont('phantommuff.ttf', 30), {1, 1, 1},
			'center', (game.width * 0.8) / 2 - 20)
		daGroup:add(valueTxt)

		gameplayTab:add(daGroup)
	end

	local linesGroup = Group()
	linesGroup.isLines = true
	linesGroup.name = gameplayTab.name

	local lines = Sprite(0, 117):make(2, game.height * 0.72,
		{255, 255, 255})
	lines:screenCenter('x')
	lines.alpha = 0.5
	linesGroup:add(lines)
	options.spriteGroup:add(linesGroup)

	options.allTabs:add(gameplayTab)
end

function Gameplay.selectOption(id, selected)
	game.sound.play(paths.getSound('scrollMenu'))
	for i, daOption in ipairs(optionsVar) do
		if i == id then
			daOption[3] = (selected ~= nil and selected or false)
			curSelected = id

			if daOption[4] == 'string' then
				stringSelected = table.find(daOption[5], ClientPrefs.data[daOption[1]])
			end
		end
	end
end

function Gameplay.changeSelection(huh)
	if huh == nil then huh = 0 end
	game.sound.play(paths.getSound('scrollMenu'))

	local selectedOption = optionsVar[curSelected]
	local optionData = selectedOption[1]
	local optionType = selectedOption[4]
	if optionType == 'boolean' then
		ClientPrefs.data[optionData] = not ClientPrefs.data[optionData]
		if selectedOption[5] then selectedOption[5]() end
	elseif optionType == 'string' then
		local stringVal = selectedOption[5]

		stringSelected = stringSelected + huh

		if stringSelected > #stringVal then
			stringSelected = 1
		elseif stringSelected < 1 then
			stringSelected = #stringVal
		end

		ClientPrefs.data[optionData] = stringVal[stringSelected]
		if selectedOption[6] then selectedOption[6]() end
	elseif optionType == 'number' then
		local minVal = selectedOption[5][1]
		local maxVal = selectedOption[5][2]

		ClientPrefs.data[optionData] = ClientPrefs.data[optionData] + huh

		if ClientPrefs.data[optionData] > maxVal then
			ClientPrefs.data[optionData] = maxVal
		elseif ClientPrefs.data[optionData] < minVal then
			ClientPrefs.data[optionData] = minVal
		end
		if selectedOption[6] then selectedOption[6]() end
	end
end

return Gameplay
