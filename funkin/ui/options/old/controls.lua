local Controls = {}

local binds = {
	{true, 'NOTES'}, {true, 'Left', 'note_left'},
	{true, 'Down',  'note_down'},
	{true, 'Up',    'note_up'},
	{true, 'Right', 'note_right'},
	{true, ''},
	{true, 'UI'}, {true, 'Left', 'ui_left'},
	{true, 'Down',   'ui_down'},
	{true, 'Up',     'ui_up'},
	{true, 'Right',  'ui_right'},
	{true, 'Reset',  'reset'},
	{true, 'Accept', 'accept'},
	{true, 'Back',   'back'},
	{true, 'Pause',  'pause'},
	{true, ''},
	{true, 'DEBUG'}, {true, 'Charting', 'debug_1'},
	{true, 'Character', 'debug_2'}
}

function Controls.add(options)
	local controlsTab = Group()
	controlsTab.name = 'Controls'

	local titleTxtGroup = Group()
	titleTxtGroup.name = controlsTab.name

	for i = 1, #binds do
		local bind = binds[i]
		if bind[1] then
			if #bind > 1 then
				local daGroup = Group()

				local isTitle = (#bind < 3)
				local isDefaultKey = (bind[2] == 'Reset to Default Keys')
				local isDisplayKey = (isTitle and not isDefaultKey)

				local yPos = (i * 45) + 80
				local control = Text(145, yPos, bind[2],
					paths.getFont('phantommuff.ttf', 30),
					{1, 1, 1}, "center", (game.width * 0.8) / 2 - 18)

				if not isTitle then
					control.alignment = "left"
					daGroup:add(control)

					local bind1 = (options.controls[bind[3]][1] and
						options.controls[bind[3]][1]:split(':')[2] or
						"___")
					local bind1Txt = Text(game.width / 2 + 10, yPos, bind1,
						paths.getFont('phantommuff.ttf', 30),
						{1, 1, 1}, "center", 230)
					daGroup:add(bind1Txt)

					local bind2 = (options.controls[bind[3]][2] and
						options.controls[bind[3]][2]:split(':')[2] or
						"___")
					local bind2Txt = Text(game.width / 2 + 260, yPos, bind2,
						paths.getFont('phantommuff.ttf', 30),
						{1, 1, 1}, "center", 230)
					daGroup:add(bind2Txt)

					controlsTab:add(daGroup)
				else
					titleTxtGroup:add(control)
				end
			end
		end
	end

	local linesGroup = Group()
	linesGroup.isLines = true
	linesGroup.name = controlsTab.name

	local lines = Sprite(0, 117):make(2, game.height * 0.72,
		{255, 255, 255})
	lines:screenCenter('x')
	lines.alpha = 0.5
	linesGroup:add(lines)

	local lines = Sprite(0, 117):make(2, game.height * 0.72,
		{255, 255, 255})
	lines:screenCenter('x')
	lines.x = lines.x + ((game.width * 0.78) / 2) / 2
	lines.alpha = 0.5
	linesGroup:add(lines)

	options.spriteGroup:add(linesGroup)

	options.textGroup:add(titleTxtGroup)
	options.allTabs:add(controlsTab)
end

function Controls.getControls()
	local controlsTable = {}
	for _, t in ipairs(binds) do
		if #t > 2 then table.insert(controlsTable, t[3]) end
	end
	if #controlsTable > 0 then return controlsTable end
	return nil
end

return Controls
