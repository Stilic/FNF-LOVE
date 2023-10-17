local PauseSubState = SubState:extend()

function PauseSubState:new()
    PauseSubState.super.new(self)

    self.menuItems = {"Resume", "Restart Song", "Options", "Exit to menu"}
    self.curSelected = 1

    self.music = game.sound.play(paths.getMusic(ClientPrefs.data.pauseMusic),
                                 0, true)

    self.bg = Sprite()
    self.bg:make(game.width, game.height, {0, 0, 0})
    self.bg.alpha = 0
    self.bg:setScrollFactor()
    self:add(self.bg)

    self.grpShitMenu = Group()
    self:add(self.grpShitMenu)

    for i = 0, #self.menuItems - 1 do
        local item =
            Alphabet(0, 70 * i + 30, self.menuItems[i + 1], true, false)
        item.isMenuItem = true
        item.targetY = i
        self.grpShitMenu:add(item)
    end

    self:changeSelection()

    Timer.tween(0.4, self.bg, {alpha = 0.6}, 'in-out-quart')
end

function PauseSubState:update(dt)
    if self.music.__volume < 0.5 then
        self.music.__volume = self.music.__volume + 0.01 * dt
    end
    PauseSubState.super.update(self, dt)

    if controls:pressed('ui_up') then self:changeSelection(-1) end
    if controls:pressed('ui_down') then self:changeSelection(1) end

    if controls:pressed('accept') then
        local daChoice = self.menuItems[self.curSelected]

        switch(daChoice, {
            ["Resume"] = function() self:close() end,
            ["Restart Song"] = function() switchState(PlayState()) end,
            ["Options"] = function ()
                OptionsState.onPlayState = true
                switchState(OptionsState())
            end,
            ["Exit to menu"] = function() switchState(FreeplayState()) end
        })
    end
end

function PauseSubState:changeSelection(huh)
    if huh == nil then huh = 0 end

    game.sound.play(paths.getSound('scrollMenu'))
    self.curSelected = self.curSelected + huh

    if self.curSelected > #self.menuItems then
        self.curSelected = 1
    elseif self.curSelected < 1 then
        self.curSelected = #self.menuItems
    end

    local bullShit = 0

    for _, item in ipairs(self.grpShitMenu.members) do
        item.targetY = bullShit - (self.curSelected - 1)
        bullShit = bullShit + 1

        item.alpha = 0.6

        if item.targetY == 0 then item.alpha = 1 end
    end
end

function PauseSubState:close()
    self.music:release()
    PauseSubState.super.close(self)
end

return PauseSubState
