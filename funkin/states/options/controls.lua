local Controls = {}

function Controls.add(options)
    local controlsTab = Group()
    controlsTab.name = 'Controls'

    local binds = {
        {true, 'NOTES'}, {true, 'Left', 'note_left', 'UI Left'},
        {true, 'Down', 'note_down', 'UI Down'},
        {true, 'Up', 'note_up', 'UI Up'},
        {true, 'Right', 'note_right', 'UI Right'}
    }

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
                                     {1, 1, 1})

                if not isTitle then
                    daGroup:add(control)

                    local bind1 = options.controls[bind[3]][1]:split(':')
                    local bind1Txt = Text(382, yPos, bind1[2],
                                          paths.getFont('phantommuff.ttf', 30),
                                          {1, 1, 1}, "left", 115)
                    daGroup:add(bind1Txt)
                    local bind2 = options.controls[bind[3]][2]:split(':')
                    local bind2Txt = Text(542, yPos, bind2[2],
                                          paths.getFont('phantommuff.ttf', 30),
                                          {1, 1, 1}, "left", 115)
                    daGroup:add(bind2Txt)

                    controlsTab:add(daGroup)
                else
                    titleTxtGroup:add(control)
                end
            end
        end
    end

    local linesGroup = Group()
    linesGroup.name = controlsTab.name

    local lines = Sprite(370, 117):make(2, game.height * 0.72,
                                            {255, 255, 255})
    lines.alpha = 0.5
    linesGroup:add(lines)

    local lines = Sprite(530, 117):make(2, game.height * 0.72,
                                            {255, 255, 255})
    lines.alpha = 0.5
    linesGroup:add(lines)

    options.spriteGroup:add(linesGroup)

    options.textGroup:add(titleTxtGroup)
    options.allTabs:add(controlsTab)
end

return Controls
