local ModsState = State:extend("ModsState")

function ModsState:enter()
    self.curSelected = table.find(Mods.mods, Mods.currentMod) or 1

    self.bg = Sprite()
    self.bg:loadTexture(paths.getImage('menus/menuBGBlue'))
    self.bg.color = {0.5, 0.5, 0.5}
    self.bg:setScrollFactor()
    self.bg:screenCenter()
    self:add(self.bg)

    self.cardGroup = Group()
    self:add(self.cardGroup)

    game.camera.target = {x = game.width/2, y = game.height/2}

    if #Mods.mods > 0 then
        for i = 1, #Mods.mods do
            local card = ModCard(-50 + (i * 580), 120, Mods.mods[i])
            card:screenCenter('y')
            self.cardGroup:add(card)
        end

        local cardMidPointX = self.cardGroup.members[self.curSelected].x + 210
        self.camFollow = {x = cardMidPointX, y = game.height/2}
    else
        self.camFollow = {x = game.width/2, y = game.height/2}
    end
end

function ModsState:update(dt)
    ModsState.super.update(self, dt)

    game.camera.target.x, game.camera.target.y =
        util.coolLerp(game.camera.target.x, self.camFollow.x, 0.2),
        util.coolLerp(game.camera.target.y, self.camFollow.y, 0.2)

    if #Mods.mods > 0 then
        if controls:pressed('ui_left') then self:changeSelection(-1) end
        if controls:pressed('ui_right') then self:changeSelection(1) end

        if controls:pressed('accept') then self:selectMods() end
    end

    if controls:pressed('back') then
        game.switchState(MainMenuState())
    end
end

function ModsState:selectMods()
    local selectedMods = Mods.mods[self.curSelected]
    Mods.currentMod = selectedMods

    game.sound.music:stop()
    TitleState.initialized = false
    game.switchState(TitleState())
end

function ModsState:changeSelection(change)
    if change == nil then change = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

    self.curSelected = self.curSelected + change

    if self.curSelected > #Mods.mods then
        self.curSelected = 1
    elseif self.curSelected < 1 then
        self.curSelected = #Mods.mods
    end

    local cardMidPointX = self.cardGroup.members[self.curSelected].x + 210
    self.camFollow = {x = cardMidPointX, y = game.height/2}
end

return ModsState