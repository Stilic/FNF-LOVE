local Gameplay = {}

function Gameplay.add(options)
    local gameplayTab = Group()
    gameplayTab.name = 'Gameplay'

    local optionsVar = {
        {'scrollType', 'Scroll Type'},
        {'noteSplash', 'Note Splash'},
        {'pauseMusic', 'Pause Music'}
    }

    local type_table = {
        ["string"] = true,
        ["boolean"] = false,
        ["number"] = 0
    }

    for i, daOption in ipairs(optionsVar) do
        local daGroup = Group()

        local yPos = (i * 45) + 80
        local control = Text(145, yPos, daOption[2], paths.getFont('phantommuff.ttf', 30),
                             {1, 1, 1})
        daGroup:add(control)

        local realvalue = ClientPrefs.data[daOption[1]]
        local value = type_table[type(realvalue)] and '< '..tostring(realvalue)..' >'
                                                   or tostring(realvalue)
        local valueTxt = Text(382, yPos, value,
                              paths.getFont('phantommuff.ttf', 30), {1, 1, 1})
        daGroup:add(valueTxt)

        gameplayTab:add(daGroup)
    end

    options.allTabs:add(gameplayTab)
end

return Gameplay