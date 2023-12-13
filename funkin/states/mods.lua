local ModsState = State:extend("ModsState")

function ModsState:enter()
    self.bg = Sprite()
    self.bg:loadTexture(paths.getImage('menus/menuBGBlue'))
    self.bg.color = {0.5, 0.5, 0.5}
    self.bg:setScrollFactor()
    self.bg:screenCenter()
    self:add(self.bg)
end

function ModsState:update(dt)
    ModsState.super.update(self, dt)

    if controls:pressed('back') then
        game.switchState(MainMenuState())
    end
end

return ModsState