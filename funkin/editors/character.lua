local CharacterEditor = State:extend()

function CharacterEditor:enter()
    love.mouse.setVisible(true)

    self.curSelected = 1
    self.currentAnim = 'idle'

    local bg = Sprite()
    bg:loadTexture(paths.getImage('menus/mainmenu/menuDesat'))
    bg:setScrollFactor()
    bg.color = {0.1, 0.1, 0.1}
    self:add(bg)

    self.char = Character(370, -230, 'bf', true)
    self:add(self.char)
    self.char:playAnim(self.currentAnim)

    local tabs = {'Animations'}
    self.animationTab = ui.UITabMenu(0, game.height * 0.8, tabs)
    self.animationTab.width = game.width*0.7
    self:add(self.animationTab)

    self.animInfoTxt = Text(20, 230, '', paths.getFont('phantommuff.ttf', 20))
    self:add(self.animInfoTxt)
end

function CharacterEditor:update(dt)
    CharacterEditor.super.update(self, dt)

    local curAnimData = self.char.__animations[self.currentAnim]
    local curAnimOffset = self.char.animOffsets[self.currentAnim]

    if Keyboard.justPressed.SPACE then
        self.char:playAnim(self.currentAnim, true)
    end

    if Keyboard.justPressed.A then
        self:changeAnim(-1)
    elseif Keyboard.justPressed.D then
        self:changeAnim(1)
    end

    if Keyboard.justPressed.LEFT then
        curAnimOffset.x = curAnimOffset.x - 1
        self.char:playAnim(self.currentAnim, true)
    elseif Keyboard.justPressed.RIGHT then
        curAnimOffset.x = curAnimOffset.x + 1
        self.char:playAnim(self.currentAnim, true)
    end

    local animInfo = 'Animation: '..self.currentAnim..'\n'..
                     '\nOffsets: ['..curAnimOffset.x..', '..curAnimOffset.y..']'..
                     '\nFPS: '..curAnimData.framerate..
                     '\n'
    self.animInfoTxt:setContent(animInfo)
end

function CharacterEditor:changeAnim(huh)
    self.curSelected = self.curSelected + huh

    if self.curSelected > #self.char.__animations then
        self.curSelected = 1
    elseif self.curSelected < 1 then
        self.curSelected = #self.char.__animations
    end
end

function CharacterEditor:leave()
    love.mouse.setVisible(false)
end

return CharacterEditor
