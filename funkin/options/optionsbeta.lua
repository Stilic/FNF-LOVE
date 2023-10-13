local OptionsState = State:extend()

function OptionsState:enter()
    self.curTab = 1
    self.curSelect = 1
    self.controls = table.clone(ClientPrefs.controls)

    local bg = Sprite()
    bg:loadTexture(paths.getImage('menus/mainmenu/menuBGBlue'))
    bg.color = {0.5, 0.5, 0.5}
    bg:screenCenter()
    self:add(bg)

    self.optionsTab = {
        'Controls',
        'Gameplay'
    }

    self.titleTabBG = Sprite(0, 20)
    self.titleTabBG:make(game.width * 0.8, 65, {0, 0, 0})
    self.titleTabBG.alpha = 0.7
    self.titleTabBG:screenCenter('x')
    self:add(self.titleTabBG)

    self.tabBG = Sprite(0, 105)
    self.tabBG:make(game.width * 0.8, game.height * 0.75, {0, 0, 0})
    self.tabBG.alpha = 0.7
    self.tabBG:screenCenter('x')
    self:add(self.tabBG)

    self.optionsCursor = Sprite()
    self.optionsCursor:make((game.width * 0.78), 39, {1, 1, 1})
    self.optionsCursor.alpha = 0.1
    self.optionsCursor.visible = false
    self.optionsCursor:screenCenter('x')
    self:add(self.optionsCursor)

    self.curBindSelect = 1
    self.controlsCursor = Sprite(377)
    self.controlsCursor:make(125, 39, {1, 1, 1})
    self.controlsCursor.alpha = 0.2
    self.controlsCursor.visible = false
    self:add(self.controlsCursor)

    self.titleTxt = Text(0, 30, '', paths.getFont('phantommuff.ttf', 40),
                         {1, 1, 1}, "center", game.width)
    self:add(self.titleTxt)

    self.allTabs = Group()
    self:add(self.allTabs)

    self.timerHold = 0
    self.waiting_input = false
    self.block_input = false
    self.onTab = false

    self:add_ControlsTab()
    self:add_GameplayTab()

    self:changeTab()

    self.blackFG = Sprite()
    self.blackFG:make(game.width, game.height, {0, 0, 0})
    self.blackFG.alpha = 0
    self:add(self.blackFG)

    self.waitInputTxt = Text(0, 0, 'Rebinding..', paths.getFont('phantommuff.ttf', 60),
                             {1, 1, 1}, "center", game.width)
    self.waitInputTxt:screenCenter('y')
    self.waitInputTxt.visible = false
    self:add(self.waitInputTxt)
end

function OptionsState:reset_Tabs()
    self.allTabs:clear()
    self:add_ControlsTab()
    self:add_GameplayTab()

    for i, grp in ipairs(self.allTabs.members) do
        for j, obj in ipairs(grp.members) do
            obj.visible = (grp.name == self.optionsTab[self.curTab])
        end
    end
end

function OptionsState:add_ControlsTab()
    local controlsTab = Group()
    controlsTab.name = 'Controls'

    -- NOTE
    for i, text in ipairs({'Left', 'Down', 'Up', 'Right'}) do
        local daGroup = Group()

        local yPos = (i * 45) + 80
        local control = Text(145, yPos, 'Note ' .. text, paths.getFont('phantommuff.ttf', 30),
                             {1, 1, 1})
        daGroup:add(control)

        local bind1 = self.controls['note_'..text:lower()][1]:split(':')
        local bind1Txt = Text(382, yPos, bind1[2], paths.getFont('phantommuff.ttf', 30),
                             {1, 1, 1}, "left", 115)
        daGroup:add(bind1Txt)
        local bind2 = self.controls['note_'..text:lower()][2]:split(':')
        local bind2Txt = Text(542, yPos, bind2[2], paths.getFont('phantommuff.ttf', 30),
                             {1, 1, 1}, "left", 115)
        daGroup:add(bind2Txt)

        controlsTab:add(daGroup)
    end
    self.allTabs:add(controlsTab)
end

function OptionsState:add_GameplayTab()
    local gameplayTab = Group()
    gameplayTab.name = 'Gameplay'

    local optionsVar = {'scrollType', 'noteSplash', 'pauseMusic'}
    local options = {'Scroll Type', 'Note Splash', 'Pause Music'}

    local type_table = {
        ["string"] = true,
        ["boolean"] = false,
        ["number"] = 0
    }

    for i, text in ipairs(options) do
        local daGroup = Group()

        local yPos = (i * 45) + 80
        local control = Text(145, yPos, text, paths.getFont('phantommuff.ttf', 30),
                             {1, 1, 1})
        daGroup:add(control)

        local realvalue = ClientPrefs.data[optionsVar[i]]
        local value = type_table[type(realvalue)] and '< '..tostring(realvalue)..' >'
                                                   or tostring(realvalue)
        local valueTxt = Text(382, yPos, value,
                              paths.getFont('phantommuff.ttf', 30), {1, 1, 1})
        daGroup:add(valueTxt)

        gameplayTab:add(daGroup)
    end

    self.allTabs:add(gameplayTab)
end

function OptionsState:update(dt)
    OptionsState.super.update(self, dt)

    if controls:pressed('back') then
        game.sound.play(paths.getSound('cancelMenu'))
        if self.waiting_input then
            self.waiting_input = false
            self.blackFG.alpha = 0
            self.waitInputTxt.visible = false
        elseif self.onTab then
            self.onTab = false
            self.titleTxt:setContent('< '..self.optionsTab[self.curTab]..' >')
            self.optionsCursor.visible = false
            self.controlsCursor.visible = (self.optionsTab[self.curTab] == 'Controls'
                                           and false)
        else
            switchState(MainMenuState())
        end
    end

   if not self.waiting_input then
        if not self.onTab then
            if controls:pressed('ui_left') then
                self:changeTab(-1)
            elseif controls:pressed('ui_right') then
                self:changeTab(1)
            end

            if Keyboard.justPressed.ENTER then
                self.onTab = true
                self.titleTxt:setContent(self.optionsTab[self.curTab])
                self.curSelect = 1
                self:changeSelection(nil, self.allTabs.members[self.curTab])
                self.optionsCursor.visible = true

                if self.optionsTab[self.curTab] == 'Controls' then
                    self.controlsCursor.visible = true
                end
            end
        else
            if Keyboard.justPressed.ENTER then
                if self.optionsTab[self.curTab] == 'Controls' then
                    if not self.waiting_input then
                        self.waiting_input = true
                        self.blackFG.alpha = 0.5
                        self.waitInputTxt.visible = true
                    end
                end
            end
            if controls:pressed('ui_left') then
                if self.optionsTab[self.curTab] == 'Controls' then
                    self:changeBindSelection(-1)
                end
            end
            if controls:pressed('ui_right') then
                if self.optionsTab[self.curTab] == 'Controls' then
                    self:changeBindSelection(1)
                end
            end
            if controls:pressed('ui_up') then
                self:changeSelection(-1, self.allTabs.members[self.curTab])
                self.timerHold = 0
            elseif controls:pressed('ui_down') then
                self:changeSelection(1, self.allTabs.members[self.curTab])
                self.timerHold = 0
            end
            if controls:down('ui_up') or controls:down('ui_down') then
                self.timerHold = self.timerHold + dt
                if self.timerHold > 0.5 then
                    self.timerHold = 0.4
                    self:changeSelection((controls:down('ui_up') and -1 or 1),
                                         self.allTabs.members[self.curTab])
                end
            end
        end
    elseif Keyboard.input and self.waiting_input and not self.block_input then
        game.sound.play(paths.getSound('confirmMenu'))
        self.block_input = true

        local arrow = {'left', 'down', 'up', 'right'}
        local text = arrow[self.curSelect]

        local newBind = 'key:'..Keyboard.input:lower()
        self.controls['note_'..text][self.curBindSelect] = newBind

        self:reset_Tabs()

        self.waitInputTxt:setContent('Configuring..\nPlease Wait')
        Timer.after(1, function()
            self.block_input = false
            self.waiting_input = false
            self.blackFG.alpha = 0
            self.waitInputTxt.visible = false
            self.waitInputTxt:setContent('Rebinding..')

            ClientPrefs.controls = table.clone(self.controls)
            controls = (require "lib.baton").new({
                controls = table.clone(self.controls)
            })
        end)
    end
end

function OptionsState:changeBindSelection(huh)
    huh = huh or 0

    game.sound.play(paths.getSound('scrollMenu'))
    self.curBindSelect = self.curBindSelect + huh
    if self.curBindSelect > 2 then
        self.curBindSelect = 1
    elseif self.curBindSelect < 1 then
        self.curBindSelect = 2
    end

    self.controlsCursor.x = (self.curBindSelect == 1 and 382
                          or self.curBindSelect == 2 and 542) - 5
end

function OptionsState:changeSelection(huh, tab)
    huh = huh or 0

    game.sound.play(paths.getSound('scrollMenu'))
    self.curSelect = self.curSelect + huh
    if self.curSelect > #tab.members then
        self.curSelect = 1
    elseif self.curSelect < 1 then
        self.curSelect = #tab.members
    end

    local yPos = (self.curSelect * 45) + 76
    self.optionsCursor.y = yPos
    if self.optionsTab[self.curTab] == 'Controls' then
        self.controlsCursor.y = yPos
    end
end

function OptionsState:changeTab(huh)
    huh = huh or 0

    game.sound.play(paths.getSound('scrollMenu'))
    self.curTab = self.curTab + huh
    if self.curTab > #self.optionsTab then
        self.curTab = 1
    elseif self.curTab < 1 then
        self.curTab = #self.optionsTab
    end

    self.titleTxt:setContent('< '..self.optionsTab[self.curTab]..' >')

    for i, grp in ipairs(self.allTabs.members) do
        for j, obj in ipairs(grp.members) do
            obj.visible = (grp.name == self.optionsTab[self.curTab])
        end
    end
end

return OptionsState