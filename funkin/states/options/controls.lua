local Controls = {}

local lastID = 0
function Controls.add(options)
    local controlsTab = Group()
    controlsTab.name = 'Controls'

    local binds = {
        {true, 'NOTES'},
        {true, 'Left', 'note_left', 'UI Left'},
        {true, 'Down', 'note_down', 'UI Down'},
        {true, 'Up', 'note_up', 'UI Up'},
        {true, 'Right', 'note_right', 'UI Right'},
        {true},
        {true, 'UI'},
        {true, 'Left', 'ui_left', 'UI Left'},
        {true, 'Down', 'ui_down', 'UI Down'},
        {true, 'Up', 'ui_up', 'UI Up'},
        {true, 'Right', 'ui_right', 'UI Right'},
        {true},
        --{true, 'Reset', 'reset', 'Reset'},
        {true, 'Accept', 'accept', 'Accept'},
        {true, 'Back', 'back', 'Back'},
        {true, 'Pause', 'pause', 'Pause'},
		--[[{false},
		{false, 'VOLUME'},
		{false, 'Mute', 'volume_mute', 'Volume Mute'},
		{false, 'Up', 'volume_up', 'Volume Up'},
		{false, 'Down', 'volume_down', 'Volume Down'},
		{false},
		{false, 'DEBUG'},
		{false, 'Key 1', 'debug_1', 'Debug Key #1'},
		{false, 'Key 2', 'debug_2', 'Debug Key #2'}]]
    }

    local titleTxtGroup = Group()
    titleTxtGroup.name = 'Controls'

    local myID = 0
    for i = 1, #binds do
        local bind = binds[i]
        if bind[1] then
            if #bind > 1 then
                local daGroup = Group()

                local isTitle = (#bind < 3)
                local isDefaultKey = (bind[2] == 'Reset to Default Keys')
                local isDisplayKey = (isTitle and not isDefaultKey)

                local yPos = (i * 45) + 80
                local control = Text(145, yPos, bind[2], paths.getFont('phantommuff.ttf', 30),
                             {1, 1, 1})

                if not isTitle then
                    daGroup:add(control)

                    local bind1 = options.controls[bind[3]][1]:split(':')
                    local bind1Txt = Text(382, yPos, bind1[2], paths.getFont('phantommuff.ttf', 30),
                                        {1, 1, 1}, "left", 115)
                    daGroup:add(bind1Txt)
                    local bind2 = options.controls[bind[3]][2]:split(':')
                    local bind2Txt = Text(542, yPos, bind2[2], paths.getFont('phantommuff.ttf', 30),
                                        {1, 1, 1}, "left", 115)
                    daGroup:add(bind2Txt)

                    controlsTab:add(daGroup)
                else
                    titleTxtGroup:add(control)
                end
            end
        end
    end
    options.textGroup:add(titleTxtGroup)
    options.allTabs:add(controlsTab)
end

return Controls