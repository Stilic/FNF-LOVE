local UpdateState = State:extend("UpdateState")

local updateVersion = ''

function UpdateState:new(version)
    UpdateState.super.new(self)
    if version then updateVersion = version end
end

function UpdateState:enter()
    local bg = Sprite():loadTexture(paths.getImage('menus/menuDesat'))
    bg.color = {0.1, 0.1, 0.1}
    self:add(bg)

    local textmoment = "Oh look, an update! you are running an outdated version."
                    .. "\nCurrent Version: " .. Application.version
                    .. " - Update Version: " .. updateVersion
                    .. "\n\n Press BACK to proceed."

    local textupdate = Text(0, 0, textmoment, paths.getFont('phantommuff.ttf', 30),
                            {1, 1, 1}, 'center')
    textupdate:screenCenter()
    textupdate.y = textupdate.y - 40
    self:add(textupdate)

    self.blackScreen = Sprite():make(game.width, game.height, {0, 0, 0})
    self.blackScreen.visible = false
    self:add(self.blackScreen)
end

function UpdateState:update(dt)
    if controls:pressed('accept') then
        love.system.openURL('https://github.com/Stilic/FNF-LOVE/tree/main')
        game.switchState(TitleState())
    elseif controls:pressed('back') then
        game.sound.play(paths.getSound('cancelMenu'))
        self.blackScreen.visible = true
        game.switchState(TitleState())
    end
end

return UpdateState