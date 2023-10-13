local encodeJson = require('lib.json').encode

local CharacterEditor = State:extend()

CharacterEditor.onPlayState = false

function CharacterEditor:enter()
    love.mouse.setVisible(true)

    Character.editorMode = true

    self.curChar = 'bf'
    self.curSelected = 1
    self.curAnim = nil
    self.isPlayer = true

    if CharacterEditor.onPlayState then
        self.curChar = PlayState.SONG.player2
        self.isPlayer = self.curChar:startsWith('bf')
    end

    self.camEditor = Camera()
    self.camEditor.scroll = {x = 0, y = 0}
    self.camMenu = Camera()

    game.cameras.reset(self.camEditor)
    game.cameras.add(self.camMenu, false)

    local bg = Sprite(-600, -200):loadTexture(
                   paths.getImage("stages/stage/stageback"))
    bg.antialiasing = true
    bg:setScrollFactor(0.9, 0.9)
    self:add(bg)

    local stageFront = Sprite(-650, 600):loadTexture(
                           paths.getImage("stages/stage/stagefront"))
    stageFront:setGraphicSize(math.floor(stageFront.width * 1.1))
    stageFront:updateHitbox()
    stageFront.antialiasing = true
    stageFront:setScrollFactor(0.9, 0.9)
    self:add(stageFront)

    self.charLayer = Group()
    self:add(self.charLayer)

    self:loadCharacter()

    self:changeAnim()

    self.camPoint1 = Sprite()
    self.camPoint1:make(5, 30, {1, 1, 1})
    self:add(self.camPoint1)

    self.camPoint2 = Sprite()
    self.camPoint2:make(30, 5, {1, 1, 1})
    self:add(self.camPoint2)

    self.blockInput = {}

    self.animationTab = ui.UITabMenu(0, game.height * 0.8, {'Animation'})
    self.animationTab.width = game.width * 0.7
    self.animationTab.height = game.height * 0.2
    self:add(self.animationTab)

    self.charTab = ui.UITabMenu(game.width * 0.7, game.height * 0.6, {'Character'})
    self.charTab.width = game.width * 0.3
    self.charTab.height = game.height * 0.4
    self:add(self.charTab)

    self.animInfoTxt = Text(20, 230, '', paths.getFont('phantommuff.ttf', 20))
    self:add(self.animInfoTxt)

    self.charInfoTxt = Text(20, 20, '', paths.getFont('phantommuff.ttf', 14))
    self:add(self.charInfoTxt)

    self:add_UI_Character()

    for _, o in ipairs({
        self.animationTab, self.charTab, self.animInfoTxt, self.charInfoTxt
    }) do o.cameras = {self.camMenu} end
end

function CharacterEditor:add_UI_Character()
    local tab_char = Group()
    tab_char.name = 'Character'

    local save_char = ui.UIButton(140, 10, 100, 20, 'Save', function()
        self:saveCharacter()
    end)

    local playable_check = ui.UICheckbox(10, 40, 20)
    playable_check.checked = self.isPlayer
    playable_check.callback = function()
        self.isPlayer = not self.isPlayer

        self.char.__reverseDraw = not self.char.__reverseDraw
        self.char:switchAnim("singLEFT", "singRIGHT")
        self.char:switchAnim("singLEFTmiss", "singRIGHTmiss")
        self.char:switchAnim("singLEFT-loop", "singRIGHT-loop")
        self.char.flipX = not self.char.flipX

        self.char.x = (self.isPlayer and 770 or 100) + self.char.positionTable.x
        self.char.y = 100 + self.char.positionTable.y
        self.camEditor.scroll = {x = (self.isPlayer and 350 or -310), y = 294}

        if self.char.curAnim.name:find('LEFT') or self.char.curAnim.name:find('RIGHT') then
            self.char:playAnim(self.curAnim.anim, true)
        end
    end

    local flipX_check = ui.UICheckbox(10, 70, 20)
    flipX_check.checked = self.char.flipX
    if self.isPlayer then flipX_check.checked = not flipX_check.checked end
    flipX_check.callback = function()
        self.char.jsonFlipX = not self.char.jsonFlipX
        self.char.flipX = self.char.jsonFlipX
        if self.isPlayer then self.char.flipX = not self.char.flipX end
    end

    local camX_stepper = ui.UINumericStepper(10, 130, 10,
                                             self.char.cameraPosition.x, -9000, 9000)
    camX_stepper.onChanged = function(value) self.char.cameraPosition.x = value end

    local camY_stepper = ui.UINumericStepper(camX_stepper.x + 90, camX_stepper.y, 10,
                                             self.char.cameraPosition.y, -9000, 9000)
    camY_stepper.onChanged = function(value) self.char.cameraPosition.y = value end

    local posX_stepper = ui.UINumericStepper(camX_stepper.x, camX_stepper.y + 50, 10,
                                             self.char.positionTable.x, -9000, 9000)
    posX_stepper.onChanged = function(value)
        self.char.positionTable.x = value
        self.char.x = (self.isPlayer and 770 or 100) + self.char.positionTable.x
    end
    local posY_stepper = ui.UINumericStepper(posX_stepper.x + 90, posX_stepper.y, 10,
                                             self.char.positionTable.y, -9000, 9000)
    posY_stepper.onChanged = function(value)
        self.char.positionTable.y = value
        self.char.y = 100 + self.char.positionTable.y
    end

    local optionsChar = {}
    for _, str in pairs(love.filesystem.getDirectoryItems(
                        paths.getPath('data/characters'))) do
        local charName = str:withoutExt()
        if str:endsWith('.json') and not charName:endsWith('-dead') then
            table.insert(optionsChar, charName)
        end
    end

    local char_dropdown = ui.UIDropDown(10, 10, optionsChar)
    char_dropdown.selectedLabel = self.curChar
    char_dropdown.onChanged = function(value)
        self.isPlayer = value:startsWith('bf')
        playable_check.checked = self.isPlayer

        self.curChar = value
        self:loadCharacter()

        camX_stepper.value = tostring(self.char.cameraPosition.x)
        camY_stepper.value = tostring(self.char.cameraPosition.y)

        posX_stepper.value = tostring(self.char.positionTable.x)
        posY_stepper.value = tostring(self.char.positionTable.y)

        flipX_check.checked = self.char.flipX
        if self.isPlayer then flipX_check.checked = not flipX_check.checked end
    end

    tab_char:add(Text(38, 43, 'Playable Character'))
    tab_char:add(Text(38, 73, 'flipX'))
    tab_char:add(Text(10, camX_stepper.y - 20, 'Camera X/Y'))
    tab_char:add(Text(10, posX_stepper.y - 20, 'Position X/Y'))
    tab_char:add(flipX_check)
    tab_char:add(playable_check)
    tab_char:add(camX_stepper)
    tab_char:add(camY_stepper)
    tab_char:add(posX_stepper)
    tab_char:add(posY_stepper)
    tab_char:add(save_char)
    tab_char:add(char_dropdown)

    table.insert(self.blockInput, camX_stepper)
    table.insert(self.blockInput, camY_stepper)
    table.insert(self.blockInput, posX_stepper)
    table.insert(self.blockInput, posY_stepper)

    self.charTab:addGroup(tab_char)
end

function updateCamPoint(self)
    local midPointX, midPointY = self.char:getMidpoint()
    midPointX = midPointX + (self.isPlayer and -100 or 150)
    midPointY = midPointY + -100

    self.camPoint1.x, self.camPoint1.y = midPointX - 2.5, midPointY - 15
    self.camPoint2.x, self.camPoint2.y = midPointX - 15, midPointY - 2.5

    local camPosX, camPosY = self.char.cameraPosition.x,
                             self.char.cameraPosition.y
    camPosX = (self.isPlayer and -camPosX or camPosX)

    self.camPoint1.x, self.camPoint1.y = self.camPoint1.x + camPosX,
                                         self.camPoint1.y + camPosY
    self.camPoint2.x, self.camPoint2.y = self.camPoint2.x + camPosX,
                                         self.camPoint2.y + camPosY
end

function CharacterEditor:update(dt)
    CharacterEditor.super.update(self, dt)

    local isTyping = false
    for _, inputObj in ipairs(self.blockInput) do
        if inputObj.active then isTyping = true
            break
        end
        isTyping = false
    end

    if not isTyping then
        if Keyboard.justPressed.SPACE then
            self.char:playAnim(self.curAnim.anim, true)
        end

        local shiftMult = Keyboard.pressed.SHIFT and 10 or 1

        if Keyboard.pressed.J then
            self.camEditor.scroll.x = self.camEditor.scroll.x - (2 + shiftMult)
        elseif Keyboard.pressed.L then
            self.camEditor.scroll.x = self.camEditor.scroll.x + (2 + shiftMult)
        end
        if Keyboard.pressed.I then
            self.camEditor.scroll.y = self.camEditor.scroll.y - (2 + shiftMult)
        elseif Keyboard.pressed.K then
            self.camEditor.scroll.y = self.camEditor.scroll.y + (2 + shiftMult)
        end
        if Keyboard.pressed.U then
            self.camEditor.zoom = self.camEditor.zoom - 0.01
        elseif Keyboard.pressed.O then
            self.camEditor.zoom = self.camEditor.zoom + 0.01
        end

        if Keyboard.justPressed.LEFT then
            self.curAnim.offsets[1] = self.curAnim.offsets[1] + shiftMult
            self:changeOffsets(self.curAnim.offsets[1], self.curAnim.offsets[2])
        elseif Keyboard.justPressed.RIGHT then
            self.curAnim.offsets[1] = self.curAnim.offsets[1] - shiftMult
            self:changeOffsets(self.curAnim.offsets[1], self.curAnim.offsets[2])
        end
        if Keyboard.justPressed.UP then
            self.curAnim.offsets[2] = self.curAnim.offsets[2] + shiftMult
            self:changeOffsets(self.curAnim.offsets[1], self.curAnim.offsets[2])
        elseif Keyboard.justPressed.DOWN then
            self.curAnim.offsets[2] = self.curAnim.offsets[2] - shiftMult
            self:changeOffsets(self.curAnim.offsets[1], self.curAnim.offsets[2])
        end

        if Keyboard.justPressed.A then
            self:changeAnim(-1)
        elseif Keyboard.justPressed.D then
            self:changeAnim(1)
        end

        if Keyboard.justPressed.ESCAPE then
            if CharacterEditor.onPlayState then
                CharacterEditor.onPlayState = false
                switchState(PlayState())
            else
                switchState(MainMenuState())
            end
        end
    end

    updateCamPoint(self)

    local animInfo = 'Current Animation\n'..
                     '\nName: '..self.curAnim.anim..
                     '\nOffsets: ['..self.curAnim.offsets[1]..', '
                                   ..self.curAnim.offsets[2]..']'..
                     '\nFPS: '..self.curAnim.fps
    self.animInfoTxt:setContent(animInfo)

    local charInfo = 'Current Character\n'..
                     '\nName: '..self.curChar..
                     '\nImage: '..self.char.imageFile..
                     '\nIcon: '..self.char.icon..
                     '\nFlip X: '..tostring(self.char.jsonFlipX)
    self.charInfoTxt:setContent(charInfo)
end

function CharacterEditor:loadCharacter()
    self.charLayer:clear()
    self.char = Character(0, 0, self.curChar, self.isPlayer)
    self.charLayer:add(self.char)
    if self.char.animationsTable[1] ~= nil then
        self.char:playAnim(self.char.animationsTable[1].anim, true)
    end

    self.curSelected = 1
    self.curAnim = self.char.animationsTable[self.curSelected]

    self.char.x = (self.isPlayer and 770 or 100) + self.char.positionTable.x
    self.char.y = 100 + self.char.positionTable.y
    self.camEditor.scroll = {x = (self.isPlayer and 350 or -310), y = 294}
end

function CharacterEditor:changeOffsets(x, y)
    self.char.offset.x, self.char.offset.y = x, y
    self.char.animOffsets[self.curAnim.anim] = {x = x, y = y}
end

function CharacterEditor:changeAnim(huh)
    huh = huh or 0
    self.curSelected = self.curSelected + huh

    if self.curSelected > #self.char.animationsTable then
        self.curSelected = 1
    elseif self.curSelected < 1 then
        self.curSelected = #self.char.animationsTable
    end

    self.curAnim = self.char.animationsTable[self.curSelected]
    self.char:playAnim(self.curAnim.anim, true)
end

function CharacterEditor:saveCharacter()
    local file = WindowDialogue.askSaveAsFile(nil, {{"JSON Files", "*.json"}}, self.curChar..".json")

    if file then
        local animationsTable = self.char.animationsTable
        local positionTable = self.char.positionTable
        local cameraPosition = self.char.cameraPosition
        local charData = {
            animations = animationsTable,
            image = self.char.imageFile,
            position = {
                positionTable.x,
                positionTable.y
            },
            healthicon = self.char.icon,
            flip_x = self.char.jsonFlipX,
            no_antialiasing = self.char.noAntialiasing,
            camera_position = {
                cameraPosition.x,
                cameraPosition.y
            },
            scale = self.char.jsonScale
        }

        local json_file = io.open(file, "wb")
        json_file:write(encodeJson(charData))
        json_file:close()
    end
end

function CharacterEditor:leave()
    love.mouse.setVisible(false)
    Character.editorMode = false
end

return CharacterEditor
