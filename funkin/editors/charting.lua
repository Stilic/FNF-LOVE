local ChartingState = State:extend()

ChartingState.songPosition = 0

function ChartingState:enter()
    love.mouse.setVisible(true)

    self.curSection = 0

    self.bg = Sprite()
    self.bg:loadTexture(paths.getImage("menus/mainmenu/menuDesat"))
    self.bg:screenCenter()
    self.bg.color = {0.1, 0.1, 0.1}
    self.bg:setScrollFactor()
    self:add(self.bg)

    if PlayState.SONG ~= nil then
        self.__song = PlayState.SONG
    else
        self.__song = {
            song = 'Test',
            bpm = 150.0,
            speed = 1,
            needsVoices = true,
            stage = 'stage',
            player1 = 'bf',
            player2 = 'dad',
            gfVersion = 'gf',
            notes = {}
        }
        addSection(self)
        PlayState.SONG = self.__song
    end

    self.camScroll = Camera()
    self.camScroll.target = {x = 640, y = 360}
    game.cameras.reset(self.camScroll)

    self.strumLine = {x = 640, y = 360}

    self.gridSize = 40
    self.strumOffset = self.gridSize * 5

    -- fuckin' grid
    self.gridBox = ui.UIGrid(self.gridSize * 6, 0, 16, 8, self.gridSize, {0.9,0.9,0.9}, {0.7,0.7,0.7})
    self.gridBG = ui.UIGrid(self.gridSize * 6, 0, 64, 8, self.gridSize, {0.9,0.9,0.9}, {0.7,0.7,0.7})
    self.gridBG_highlight = ui.UIGrid(0, 0, 16, 2, self.gridSize * 4, {0,0,0,0}, {0,0,0,0.4})

    self:add(self.gridBox)
    --self:add(self.gridBG)
    --self:add(self.gridBG_highlight)

    self.curRenderedNotes = Group()
    self:add(self.curRenderedNotes)

    local daBlack = Sprite(self.gridBox.x, 0)
    daBlack:setScrollFactor()
    daBlack:make(self.gridSize * 8, (self.gridSize * 4), {0, 0, 0})
    daBlack.alpha = 0.4
    self:add(daBlack)

    local blackLine = Sprite(self.gridBox.x + (self.gridSize * 4) - 1, 0)
    blackLine:setScrollFactor(1, 0)
    blackLine:make(2, game.height, {0, 0, 0})
    self:add(blackLine)

    local curPosLine = Sprite(self.gridBox.x, (self.gridSize * 4) - 1)
    curPosLine:setScrollFactor()
    curPosLine:make(self.gridSize * 8, 2, {0, 1, 0})
    self:add(curPosLine)

    local testText = Text((self.gridBox.x - 50), self.gridBox.y, '', paths.getFont("vcr.ttf", 16), {1, 1, 1})
    testText:setContent(tostring(self.gridSize * 4) .. '\n' .. tostring((self.gridSize * 4) + self.gridBox.height))
    self:add(testText)

    self.iconLeft = HealthIcon('dad')
    self.iconLeft.x, self.iconLeft.y = self.gridBox.x + (self.gridSize + 5), self.gridSize - 35
    self.iconLeft:setScrollFactor()
    self.iconLeft:swap(1)

    self.iconRight = HealthIcon('bf')
    self.iconRight.x, self.iconRight.y = self.gridBox.x + (self.gridSize * 5) + 5, self.gridSize - 35
    self.iconRight:setScrollFactor()
    self.iconRight:swap(1)

    self.iconLeft:setGraphicSize(0, 80)
    self.iconRight:setGraphicSize(0, 80)

    self:add(self.iconLeft)
    self:add(self.iconRight)

    loadSong(self, self.__song.song)

    updateIcon(self)

    self.blockInput = {}

    self.dummyArrow = Sprite()
    self.dummyArrow:make(self.gridSize, self.gridSize, {1, 1, 1})
    self:add(self.dummyArrow)

    local tabs = {
        "Charting",
        "Note",
        "Section",
        "Song",
    }
    self.UI_Box = ui.UITabMenu(890, 40, tabs)
    self.UI_Box.height = (game.height - self.UI_Box.tabHeight) - (self.UI_Box.y * 2)

    self:add(self.UI_Box)
    self:add_UI_Song()
    self:add_UI_Section()

    updateGrid(self)
end

function ChartingState:add_UI_Song()

    local input_song = ui.UIInputTextBox(45, 10, 135, 20)
    input_song.text = self.__song.song
    input_song.onChanged = function(value) self.__song.song = value end

    local load_audio_button = ui.UIButton(300, 10, 80, 20, 'Load Audio', function()
        loadSong(self, input_song.text)
    end)

    local save_song_button = ui.UIButton(200, 10, 80, 20, 'Save')

    local voice_track = ui.UICheckbox(10, 40, 20)
    voice_track.checked = self.__song.needsVoices
    voice_track.callback = function() self.__song.needsVoices = voice_track.checked end

    local bpm_stepper = ui.UINumericStepper(10, 100, 1, self.__song.bpm, 1, 400)
    bpm_stepper.onChanged = function(value)
        self.__song.bpm = value
        ChartingState.inst:setBPM(value)
    end

    local speed_stepper = ui.UINumericStepper(10, 160, 0.1, self.__song.speed, 0.1, 10)
    speed_stepper.onChanged = function(value) self.__song.speed = value end

    local optionsChar = {}
    for i, str in pairs(love.filesystem.getDirectoryItems(paths.getPath('data/characters'))) do
        local charName = str:withoutExt()
        if not charName:endsWith('-dead') then table.insert(optionsChar, charName) end
    end

    local boyfriend_dropdown = ui.UIDropDown(10, 210, optionsChar)
    boyfriend_dropdown.selectedLabel = self.__song.player1
    boyfriend_dropdown.onChanged = function(value)
        self.__song.player1 = value
        updateIcon(self)
    end

    local opponent_dropdown = ui.UIDropDown(10, 270, optionsChar)
    opponent_dropdown.selectedLabel = self.__song.player2
    opponent_dropdown.onChanged = function(value)
        self.__song.player2 = value
        updateIcon(self)
    end

    local girlfriend_dropdown = ui.UIDropDown(10, 330, optionsChar)
    girlfriend_dropdown.selectedLabel = self.__song.gfVersion
    girlfriend_dropdown.onChanged = function(value) self.__song.gfVersion = value end

    local optionsStage = {}
    for i, str in pairs(love.filesystem.getDirectoryItems(paths.getPath('data/stages'))) do
        local stageName = str:withoutExt()
        table.insert(optionsStage, stageName)
    end

    local stage_dropdown = ui.UIDropDown(140, 210, optionsStage)
    stage_dropdown.selectedLabel = self.__song.stage
    stage_dropdown.onChanged = function(value) self.__song.stage = value end

    local tab_song = Group()
    tab_song.name = "Song"

    table.insert(self.blockInput, input_song)
    table.insert(self.blockInput, bpm_stepper)
    table.insert(self.blockInput, speed_stepper)

    tab_song:add(Text(4, 10, "Song:"))
    tab_song:add(input_song)
    tab_song:add(Text(34, 43, "Has voice track"))
    tab_song:add(voice_track)
    tab_song:add(Text(10, 80, "Song BPM:"))
    tab_song:add(bpm_stepper)
    tab_song:add(Text(10, 140, "Song Speed:"))
    tab_song:add(speed_stepper)
    tab_song:add(load_audio_button)
    tab_song:add(save_song_button)
    tab_song:add(Text(10, 310, "Girlfriend:"))
    tab_song:add(girlfriend_dropdown)
    tab_song:add(Text(10, 250, "Opponent:"))
    tab_song:add(opponent_dropdown)
    tab_song:add(Text(10, 190, "Boyfriend:"))
    tab_song:add(boyfriend_dropdown)
    tab_song:add(stage_dropdown)

    self.UI_Box:addGroup(tab_song)
end

function ChartingState:add_UI_Section()

    self.must_hit_sec = ui.UICheckbox(10, 20, 20)
    self.must_hit_sec.checked = self.__song.notes[self.curSection+1].mustHitSection
    self.must_hit_sec.callback = function()
        self.__song.notes[self.curSection
                          +1].mustHitSection = self.must_hit_sec.checked
    end

    local tab_section = Group()
    tab_section.name = "Section"

    tab_section:add(Text(34, 23, "Must Hit Section"))
    tab_section:add(self.must_hit_sec)

    self.UI_Box:addGroup(tab_section)
end

function ChartingState:update_UI_Section()
    self.must_hit_sec.checked = self.__song.notes[self.curSection+1].mustHitSection
end

function sectionStartTime(self, add)
    add = add or 0

    local bpm = self.__song.bpm
    local pos = 0
    for i = 0,self.curSection + add do
        if self.__song.notes[i+1] ~= nil then
            if self.__song.notes[i+1].changeBPM then
                bpm = self.__song.notes[i+1].bpm
            end
            pos = pos + getSectionBeats(self, i) * (1000 * 60 / bpm)
        end
    end
    return pos
end

function ChartingState:update(dt)

    ChartingState.inst:__updateTime()

    local isTyping = false
    for _, inputObj in ipairs(self.blockInput) do
        if inputObj.active then isTyping = true
            break
        end
        isTyping = false
    end

    self.gridBG_highlight.y = self.gridBG.y
    self.gridBG_highlight.x = self.gridBG.x

    if ChartingState.inst.sound:tell() < 0 then
        ChartingState.inst.sound:pause()
        ChartingState.inst.sound:seek(0)
    elseif ChartingState.inst.sound:tell() > ChartingState.inst.sound:getDuration() then
        ChartingState.inst.sound:pause()
        ChartingState.inst.sound:seek(0)
        changeSection(self)
    end
    ChartingState.songPosition = ChartingState.inst.sound:tell() * 1000
    strumLineUpdateY(self)

    if math.ceil(self.strumLine.y) >= self.gridBox.height + self.strumOffset then
        if self.__song.notes[self.curSection+2] == nil then
            addSection(self)
        end
        changeSection(self, self.curSection + 1, false)
        --print('increased curSection')
    elseif self.strumLine.y < -10 + self.strumOffset then
        changeSection(self, self.curSection - 1, false)
        --print('decreased curSection')
    end

    if Mouse.x > self.gridBG.x and Mouse.x < self.gridBG.x + self.gridBG.width and
        Mouse.y > self.gridBox.y + (self.gridSize * 4) and Mouse.y < self.gridBG.y +
        self.camScroll.target.y < self.gridBox.y +
        (self.gridSize * getSectionBeats(self) * 4) + (self.gridSize * 9) then

        self.dummyArrow.visible = true
        self.dummyArrow.x = math.floor(Mouse.x / self.gridSize) * self.gridSize
        if Keyboard.pressed.SHIFT then
            self.dummyArrow.y = (Mouse.y + self.camScroll.target.y -
                                (self.gridSize * 9) - (self.gridSize / 2))
        else
            local gridmult = self.gridSize / (16 / 16)
            self.dummyArrow.y = math.floor(
                                    (Mouse.y + self.camScroll.target.y -
                                        (self.gridSize * 9)) / gridmult) *
                                    gridmult
        end
    else
        self.dummyArrow.visible = false
    end

    if not isTyping then

        if Mouse.justPressed then
            if Mouse.overlaps() then
                --
            else
                if Mouse.x > self.gridBG.x and Mouse.x < self.gridBG.x +
                    self.gridBG.width and Mouse.y > (self.gridSize * 4) and
                    Mouse.y < self.gridBG.y + (self.gridSize * 4 * 4) then

                    -- print('added note')
                end
            end
        end

        if Keyboard.justPressed.SPACE then
            if ChartingState.inst.sound:isPlaying() then
                ChartingState.inst.sound:pause()
                if ChartingState.vocals then
                    ChartingState.vocals:pause()
                end
            else
                if ChartingState.vocals then
                    ChartingState.vocals.__source:seek(ChartingState.inst.sound:tell())
                    ChartingState.vocals:play()
                end
                ChartingState.inst.sound:play()
            end
        end

        if Keyboard.pressed.W or Keyboard.pressed.S then
            ChartingState.inst.sound:pause()

            local shiftMult = 1
            if Keyboard.pressed.CONTROL then shiftMult = 0.25
            elseif Keyboard.pressed.SHIFT then shiftMult = 4 end

            local daTime = 700 * dt * shiftMult

            if Keyboard.pressed.W then
                local checkTime = ChartingState.inst.sound:tell() - (daTime/1000)
                if checkTime > 0 then
                    ChartingState.inst.sound:seek(ChartingState.inst.sound:tell() -
                                                    (daTime/1000))
                end
            else
                local checkLimit = ChartingState.inst.sound:tell() + (daTime/1000)
                if checkLimit < ChartingState.inst.sound:getDuration() then
                    ChartingState.inst.sound:seek(ChartingState.inst.sound:tell() +
                                                    (daTime/1000))
                else
                    ChartingState.inst.sound:seek(0)
                end
            end

            if ChartingState.vocals then
                ChartingState.vocals:pause()
                ChartingState.vocals.__source:seek(ChartingState.inst.sound:tell())
            end
        end

        if Keyboard.justPressed.ENTER then
            ChartingState.inst.sound:pause()
            if ChartingState.vocals then ChartingState.vocals:pause() end

            switchState(PlayState())
        end

        if Keyboard.justPressed.BACKSPACE then
            ChartingState.inst.sound:pause()
            if ChartingState.vocals then ChartingState.vocals:pause() end

            switchState(MainMenuState())
        end

        local shiftThing = 1
        if Keyboard.pressed.SHIFT then shiftThing = 4 end

        if Keyboard.justPressed.D then
            changeSection(self, self.curSection + shiftThing)
        end
        if Keyboard.justPressed.A then
            if self.curSection <= 0 then
                changeSection(self, #self.__song.notes-1)
            else
                changeSection(self, self.curSection - shiftThing)
            end
        end
    end

    if ChartingState.inst.sound:tell() < 0 then
        ChartingState.inst.sound:pause()
        ChartingState.inst.sound:seek(0)
    elseif ChartingState.inst.sound:tell() > ChartingState.inst.sound:getDuration() then
        ChartingState.inst.sound:pause()
        ChartingState.inst.sound:seek(0)
        changeSection(self)
    end
    ChartingState.songPosition = ChartingState.inst.sound:tell() * 1000
    strumLineUpdateY(self)

    ChartingState.super.update(self, dt)
end

function loadSong(self, song)
    if ChartingState.inst then ChartingState.inst.sound:release() end
    if ChartingState.vocals then ChartingState.vocals:release() end

    ChartingState.inst = Conductor(game.sound.load(paths.getInst(song)),
                                   self.__song.bpm)
    ChartingState.inst.sound:setLooping(true)
    if self.__song.needsVoices then
        ChartingState.vocals = game.sound.load(paths.getVoices(song))
        if ChartingState.vocals then ChartingState.vocals.__source:setLooping(true) end
    end
    ChartingState.songPosition = ChartingState.inst.sound:tell() * 1000

    local curTime = 0
    if #self.__song.notes <= 1 then
        while curTime < ChartingState.inst.sound:getDuration() do
            addSection(self)
            curTime = curTime + (60 / self.__song.bpm) * 4000
        end
    end
end

function getYfromStrum(self, strumTime)
    return math.remapToRange(strumTime, 0,
                             16 * ChartingState.inst.stepCrochet,
                             self.gridBox.y + self.strumOffset, self.gridBox.y +
                                 self.gridBox.height + self.strumOffset)
end

function getYfromStrumNote(self, strumTime, beats)
    local value = strumTime / (beats * 4 * ChartingState.inst.stepCrochet)
    return self.gridSize * beats * 4 * 1 * value + (self.gridSize * 4)
end
function strumLineUpdateY(self)
    self.strumLine.y = getYfromStrum(self,
                                    (ChartingState.songPosition -
                                     sectionStartTime(self)) / 1 %
                                     (ChartingState.inst.stepCrochet * 16)) /
                                         (getSectionBeats(self) / 4)
    self.camScroll.target = self.strumLine
end

function changeSection(self, sec, updateMusic)
    if sec == nil then sec = 0 end
    if updateMusic == nil then updateMusic = true end

    if self.__song.notes[sec+1] ~= nil then
        self.curSection = sec
        if updateMusic then
            ChartingState.inst.sound:pause()

            ChartingState.inst.sound:seek(sectionStartTime(self) / 999)
            if ChartingState.vocals then
                ChartingState.vocals:pause()
                ChartingState.vocals.__source:seek(ChartingState.inst.sound:tell())
            end
            ChartingState.inst:__updateTime()
        end

        updateGrid(self)
        self:update_UI_Section()
    else
        changeSection(self)
    end
    ChartingState.songPosition = ChartingState.inst.sound:tell() * 1000
end

function getSectionBeats(self, section)
    if section == nil then section = self.curSection end
    local val = nil

    if self.__song.notes[section+1] ~= nil then val = self.__song.notes[section+1].sectionBeats end
    return val ~= nil and val or 4
end

function getBlankCharFunc()
    local lmfaoself = {}
    lmfaoself.x = 0
    lmfaoself.y = 0
    lmfaoself.width = 0
    lmfaoself.height = 0
    lmfaoself.icon = 'bf'
    for _, func in ipairs({"setFrames", "addAnimByPrefix", "addAnimByIndices", "addAnim", "addOffset", "updateHitbox", "setGraphicSize"}) do
        lmfaoself[func] = function() end
    end

    return lmfaoself
end

function updateIcon(self)
    local function getIconFromCharacter(char)
        local charScript = Script("characters/" .. char)
        local charObj = getBlankCharFunc()
        charScript.variables['self'] = charObj
        charScript:call('create')
        local icon = charObj.icon
        return icon
    end
    local iconLeft = getIconFromCharacter(self.__song.player2)
    local iconRight = getIconFromCharacter(self.__song.player1)

    self.iconLeft.texture = paths.getImage('icons/icon-'..iconLeft)
    self.iconRight.texture = paths.getImage('icons/icon-'..iconRight)
end

function updateGrid(self)
    for i, spr in ipairs(self.curRenderedNotes.members) do spr:destroy() end
    self.curRenderedNotes:clear()

    if self.__song.notes[self.curSection + 1].changeBPM and
        self.__song.notes[self.curSection + 1].bpm > 0 then
        ChartingState.inst:setBPM(self.__song.notes[self.curSection + 1].bpm)
    else
        local daBpm = self.__song.bpm
        for i = 1, self.curSection + 1 do
            if self.__song.notes[i].changeBPM then
                daBpm = self.__song.notes[i].bpm
            end
        end
        ChartingState.inst:setBPM(daBpm)
    end

end

function updateGrid(self)
    for i, spr in ipairs(self.curRenderedNotes.members) do spr:destroy() end
    self.curRenderedNotes:clear()

    if self.__song.notes[self.curSection+1].changeBPM and self.__song.notes[self.curSection+1].bpm > 0 then
        ChartingState.inst:setBPM(self.__song.notes[self.curSection+1].bpm)
    else
        local daBpm = self.__song.bpm
        for i = 0,self.curSection do
            if self.__song.notes[i+1].changeBPM then
                daBpm = self.__song.notes[i+1].bpm
            end
        end
        ChartingState.inst:setBPM(daBpm)
    end

    local beats = getSectionBeats(self)
    for _, i in ipairs(self.__song.notes[self.curSection+1].sectionNotes) do
        local note = setupNote(self, i)
        self.curRenderedNotes:add(note)
        note.mustPress = self.__song.notes[self.curSection+1].mustHitSection
        if i[2] > 3 then note.mustPress = not note.mustPress end
    end
end

function setupNote(self, i)
    local time = i[1]
    local data = i[2]
    local sus = i[3]

    local mustHit = self.__song.notes[self.curSection+1].mustHitSection
    local dataPos = mustHit and {4, 5, 6, 7, 0, 1, 2, 3} or {0, 1, 2, 3, 4, 5, 6, 7}

    local beats = getSectionBeats(self)

    local note = Note(time, data % 4)
    note.y = (self.gridSize * 20) + getYfromStrumNote(self, time - sectionStartTime(self), beats)
    note.x = math.floor(dataPos[data+1] * self.gridSize) + self.gridSize + (self.gridSize * 5)
    note:setGraphicSize(self.gridSize, self.gridSize)
    note:updateHitbox()

    return note
end

function addSection(self)
    local sec = {
        sectionBeats = 4,
        bpm = self.__song.bpm,
        changeBPM = false,
        mustHitSection = true,
        gfSection = false,
        sectionNotes = {},
        typeOfSection = 0,
        altAnim = false
    }

    table.insert(self.__song.notes, sec)
end

function ChartingState:draw()
    ChartingState.super.draw(self)

    love.graphics.push()

    local ogFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.setColor(1, 1, 1)
    local daText = util.floorDecimal(ChartingState.songPosition/1000, 2) ..
                   ' / ' .. util.floorDecimal(ChartingState.inst.sound:getDuration(), 2) ..
                   '\nSection: ' .. math.floor(ChartingState.inst.currentStep/16) ..
                   '\nBeat: ' .. ChartingState.inst.currentBeat ..
                   '\nStep: ' .. ChartingState.inst.currentStep
    local huh = love.graphics.newFont(15)
    huh:setFilter("nearest", "nearest")
    love.graphics.setFont(huh)
    love.graphics.print(daText, (self.gridSize * 14) + 10, 20)

    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(ogFont)
    love.graphics.pop()
end

function ChartingState:leave()
    love.mouse.setVisible(false)

    ChartingState.inst = nil
    ChartingState.vocals = nil
end

return ChartingState
