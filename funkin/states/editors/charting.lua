local ChartingState = State:extend()

ChartingState.songPosition = 0

function ChartingState:enter()
    love.mouse.setVisible(true)

    self.curSection = 0
    Note.chartingMode = true

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
        self:addSection()
        PlayState.SONG = self.__song
    end

    self.camScroll = Camera()
    self.camScroll.target = {x = 640, y = 360}
    game.cameras.reset(self.camScroll)

    self.strumLine = {x = 640, y = 360}

    self.gridSize = 40
    self.strumOffset = self.gridSize * 5

    -- fuckin' grid
    self.gridBox = ui.UIGrid(self.gridSize * 6, 0, 16, 8, self.gridSize,
                             {0.9, 0.9, 0.9}, {0.7, 0.7, 0.7})
    self.gridBG = ui.UIGrid(self.gridSize * 6, 0, 64, 8, self.gridSize,
                            {0.9, 0.9, 0.9}, {0.7, 0.7, 0.7})
    self.gridBG_highlight = ui.UIGrid(0, 0, 16, 2, self.gridSize * 4,
                                      {0, 0, 0, 0}, {0, 0, 0, 0.4})

    self:add(self.gridBox)
    -- self:add(self.gridBG)
    -- self:add(self.gridBG_highlight)

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

    local testText = Text((self.gridBox.x - 50), self.gridBox.y, '',
                          paths.getFont("vcr.ttf", 16), {1, 1, 1})
    testText:setContent(tostring(self.gridSize * 4) .. '\n' ..
                            tostring((self.gridSize * 4) + self.gridBox.height))
    self:add(testText)

    self.iconLeft = HealthIcon('dad')
    self.iconLeft.x, self.iconLeft.y = self.gridBox.x - 30, self.gridSize + 40
    self.iconLeft:setScrollFactor()
    self.iconLeft:swap(1)

    self.iconRight = HealthIcon('bf')
    self.iconRight.x, self.iconRight.y =
        self.gridBox.x + (self.gridSize * 4) - 30, self.gridSize + 40
    self.iconRight:setScrollFactor()
    self.iconRight:swap(1)

    self.iconLeft:setGraphicSize(0, 80)
    self.iconRight:setGraphicSize(0, 80)

    self:add(self.iconLeft)
    self:add(self.iconRight)

    self:loadSong(self.__song.song)

    self:updateIcon()

    self.blockInput = {}

    self.dummyArrow = Sprite()
    self.dummyArrow:make(self.gridSize, self.gridSize, {1, 1, 1})
    self:add(self.dummyArrow)

    local tabs = {"Charting", "Note", "Section", "Song"}
    self.UI_Box = ui.UITabMenu(890, 40, tabs)
    self.UI_Box.height = (game.height - self.UI_Box.tabHeight) -
                             (self.UI_Box.y * 2)

    self:add(self.UI_Box)
    self:add_UI_Song()
    self:add_UI_Section()

    self.infoTxt = Text(self.gridBG.x + (self.gridSize * 8) + 20, 20, '',
                        love.graphics.newFont(16))
    self:add(self.infoTxt)

    self:updateGrid()
end

function ChartingState:add_UI_Song()

    local input_song = ui.UIInputTextBox(45, 10, 135, 20)
    input_song.text = self.__song.song
    input_song.onChanged = function(value) self.__song.song = value end

    local load_audio_button = ui.UIButton(300, 10, 80, 20, 'Load Audio',
                                          function()
        self:loadSong(input_song.text)
    end)

    local save_song_button = ui.UIButton(200, 10, 80, 20, 'Save')

    local voice_track = ui.UICheckbox(10, 40, 20)
    voice_track.checked = self.__song.needsVoices
    voice_track.callback = function()
        self.__song.needsVoices = voice_track.checked
    end

    local bpm_stepper = ui.UINumericStepper(10, 100, 1, self.__song.bpm, 1, 400)
    bpm_stepper.onChanged = function(value)
        self.__song.bpm = value
        ChartingState.conductor:setBPM(value)
    end

    local speed_stepper = ui.UINumericStepper(10, 160, 0.1, self.__song.speed,
                                              0.1, 10)
    speed_stepper.onChanged = function(value) self.__song.speed = value end

    local optionsChar = {}
    for _, str in pairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                              'data/characters'))) do
        local charName = str:withoutExt()
        if str:endsWith('.json') and not charName:endsWith('-dead') then
            table.insert(optionsChar, charName)
        end
    end

    local boyfriend_dropdown = ui.UIDropDown(10, 210, optionsChar)
    boyfriend_dropdown.selectedLabel = self.__song.player1
    boyfriend_dropdown.onChanged = function(value)
        self.__song.player1 = value
        self:updateIcon()
    end

    local opponent_dropdown = ui.UIDropDown(10, 270, optionsChar)
    opponent_dropdown.selectedLabel = self.__song.player2
    opponent_dropdown.onChanged = function(value)
        self.__song.player2 = value
        self:updateIcon()
    end

    local girlfriend_dropdown = ui.UIDropDown(10, 330, optionsChar)
    girlfriend_dropdown.selectedLabel = self.__song.gfVersion
    girlfriend_dropdown.onChanged = function(value)
        self.__song.gfVersion = value
    end

    local optionsStage = {}
    for _, str in pairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                              'data/stages'))) do
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
    self.must_hit_sec.checked = self.__song.notes[self.curSection + 1]
                                    .mustHitSection
    self.must_hit_sec.callback = function()
        self.__song.notes[self.curSection + 1].mustHitSection =
            self.must_hit_sec.checked
    end

    local tab_section = Group()
    tab_section.name = "Section"

    tab_section:add(Text(34, 23, "Must Hit Section"))
    tab_section:add(self.must_hit_sec)

    self.UI_Box:addGroup(tab_section)
end

function ChartingState:update_UI_Section()
    self.must_hit_sec.checked = self.__song.notes[self.curSection + 1]
                                    .mustHitSection
end

function ChartingState:sectionStartTime(add)
    add = add or 0

    local bpm = self.__song.bpm
    local pos = 0
    for i = 0, self.curSection + add do
        if self.__song.notes[i + 1] ~= nil then
            if self.__song.notes[i + 1].changeBPM then
                bpm = self.__song.notes[i + 1].bpm
            end
            pos = pos + self:getSectionBeats(i) * (1000 * 60 / bpm)
        end
    end
    return pos
end

function ChartingState:update(dt)

    ChartingState.conductor:__updateTime()

    local isTyping = false
    for _, inputObj in ipairs(self.blockInput) do
        if inputObj.active then
            isTyping = true
            break
        end
        isTyping = false
    end

    self.gridBG_highlight.y = self.gridBG.y
    self.gridBG_highlight.x = self.gridBG.x

    if ChartingState.conductor.sound:tell() < 0 then
        ChartingState.conductor.sound:pause()
        ChartingState.conductor.sound:seek(0)
    elseif ChartingState.conductor.sound:tell() >
        ChartingState.conductor.sound:getDuration() then
        ChartingState.conductor.sound:pause()
        ChartingState.conductor.sound:seek(0)
        self:changeSection()
    end
    ChartingState.songPosition = ChartingState.conductor.sound:tell() * 1000
    self:strumLineUpdateY()

    if math.ceil(self.strumLine.y) >= self.gridBox.height + self.strumOffset then
        if self.__song.notes[self.curSection + 2] == nil then
            self:addSection()
        end
        self:changeSection(self.curSection + 1, false)
        print('increased curSection')
    elseif self.strumLine.y < -10 + self.strumOffset then
        self:changeSection(self.curSection - 1, false)
        print('decreased curSection')
    end

    if Mouse.x > self.gridBox.x and Mouse.x < self.gridBox.x +
        self.gridBox.width and Mouse.y > self.gridBox.y + (self.gridSize * 4) and
        Mouse.y + self.camScroll.target.y < self.gridBox.y +
        (self.gridSize * self:getSectionBeats() * 4) + (self.gridSize * 9) then

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
                if Mouse.x > self.gridBox.x and Mouse.x < self.gridBox.x +
                    self.gridBox.width and Mouse.y > self.gridBox.y +
                    (self.gridSize * 4) and Mouse.y + self.camScroll.target.y <
                    self.gridBox.y +
                    (self.gridSize * self:getSectionBeats() * 4) +
                    (self.gridSize * 9) then

                    -- print('added note')
                end
            end
        end

        if Keyboard.justPressed.SPACE then
            if ChartingState.conductor.sound:isPlaying() then
                ChartingState.conductor.sound:pause()
                if self.vocals then self.vocals:pause() end
            else
                if self.vocals then
                    self.vocals.__source:seek(
                        ChartingState.conductor.sound:tell())
                    self.vocals:play()
                end
                ChartingState.conductor.sound:play()
            end
        end

        if Keyboard.pressed.W or Keyboard.pressed.S then
            ChartingState.conductor.sound:pause()

            local shiftMult = 1
            if Keyboard.pressed.CONTROL then
                shiftMult = 0.25
            elseif Keyboard.pressed.SHIFT then
                shiftMult = 4
            end

            local daTime = 700 * dt * shiftMult

            if Keyboard.pressed.W then
                local checkTime = ChartingState.conductor.sound:tell() -
                                      (daTime / 1000)
                if checkTime > 0 then
                    ChartingState.conductor.sound:seek(
                        ChartingState.conductor.sound:tell() - (daTime / 1000))
                end
            else
                local checkLimit = ChartingState.conductor.sound:tell() +
                                       (daTime / 1000)
                if checkLimit < ChartingState.conductor.sound:getDuration() then
                    ChartingState.conductor.sound:seek(
                        ChartingState.conductor.sound:tell() + (daTime / 1000))
                else
                    ChartingState.conductor.sound:seek(0)
                end
            end

            if self.vocals then
                self.vocals:pause()
                self.vocals.__source:seek(ChartingState.conductor.sound:tell())
            end
        end

        if Keyboard.justPressed.ENTER then
            ChartingState.conductor.sound:pause()
            if self.vocals then self.vocals:pause() end

            game.switchState(PlayState())
        end

        if Keyboard.justPressed.BACKSPACE then
            ChartingState.conductor.sound:pause()
            if self.vocals then self.vocals:pause() end

            game.switchState(MainMenuState())
        end

        local shiftThing = 1
        if Keyboard.pressed.SHIFT then shiftThing = 4 end

        if Keyboard.justPressed.D then
            self:changeSection(self.curSection + shiftThing)
        end
        if Keyboard.justPressed.A then
            if self.curSection <= 0 then
                self:changeSection(#self.__song.notes - 1)
            else
                self:changeSection(self.curSection - shiftThing)
            end
        end
    end

    if ChartingState.conductor.sound:tell() < 0 then
        ChartingState.conductor.sound:pause()
        ChartingState.conductor.sound:seek(0)
    elseif ChartingState.conductor.sound:tell() >
        ChartingState.conductor.sound:getDuration() then
        ChartingState.conductor.sound:pause()
        ChartingState.conductor.sound:seek(0)
        self:changeSection()
    end
    ChartingState.songPosition = ChartingState.conductor.sound:tell() * 1000
    self:strumLineUpdateY()

    local daText = util.floorDecimal(ChartingState.songPosition / 1000, 2) ..
                       ' / ' ..
                       util.floorDecimal(
                           ChartingState.conductor.sound:getDuration(), 2) ..
                       '\nSection: ' .. self.curSection .. '\nBeat: ' ..
                       ChartingState.conductor.currentBeat .. '\nStep: ' ..
                       ChartingState.conductor.currentStep .. '\n\nStrumLineY: ' ..
                       self.strumLine.y .. '\nCeil StrumLineY: ' ..
                       math.ceil(self.strumLine.y) .. '\nGridBox Height: ' ..
                       (self.gridBox.height + self.strumOffset) .. '\n' ..
                       util.floorDecimal(self.strumLine.y, 2) .. ' >= ' ..
                       (self.gridBox.height + self.strumOffset)
    self.infoTxt:setContent(daText)

    ChartingState.super.update(self, dt)
end

function ChartingState:loadSong(song)
    if ChartingState.conductor then ChartingState.conductor.sound:release() end
    if self.vocals then self.vocals:release() end

    game.sound.music = Sound():load(paths.getInst(song))
    ChartingState.conductor = Conductor(game.sound.music, self.__song.bpm)
    ChartingState.conductor.sound:setLooping(true)
    if self.__song.needsVoices then
        self.vocals = Sound():load(paths.getVoices(song))
        game.sound.list:add(self.vocals)
        if self.vocals then self.vocals.__source:setLooping(true) end
    end
    ChartingState.songPosition = ChartingState.conductor.sound:tell() * 1000

    local curTime = 0
    if #self.__song.notes <= 1 then
        while curTime < ChartingState.conductor.sound:getDuration() do
            self:addSection()
            curTime = curTime + (60 / self.__song.bpm) * 4000
        end
    end
end

function ChartingState:getYfromStrum(strumTime)
    return math.remapToRange(strumTime, 0,
                             16 * ChartingState.conductor.stepCrochet,
                             self.gridBox.y + self.strumOffset, self.gridBox.y +
                                 self.gridBox.height + self.strumOffset)
end

function ChartingState:getYfromStrumNote(strumTime, beats)
    local value = strumTime / (beats * 4 * ChartingState.conductor.stepCrochet)
    return self.gridSize * beats * 4 * 1 * value + (self.gridSize * 4)
end

function ChartingState:strumLineUpdateY()
    self.strumLine.y = self:getYfromStrum(
                           (ChartingState.songPosition - self:sectionStartTime()) /
                               1 % (ChartingState.conductor.stepCrochet * 16)) /
                           (self:getSectionBeats() / 4)
    self.camScroll.target = self.strumLine
end

function ChartingState:changeSection(sec, updateMusic)
    if sec == nil then sec = 0 end
    if updateMusic == nil then updateMusic = true end

    if self.__song.notes[sec + 1] ~= nil then
        self.curSection = sec
        if updateMusic then
            ChartingState.conductor.sound:pause()

            ChartingState.conductor.sound:seek(self:sectionStartTime() / 1000)
            if self.vocals then
                self.vocals:pause()
                self.vocals.__source:seek(ChartingState.conductor.sound:tell())
            end
            ChartingState.conductor:__updateTime()
        end

        self:updateGrid()
        self:update_UI_Section()
    else
        self:changeSection()
    end
    ChartingState.songPosition = ChartingState.conductor.sound:tell() * 1000
end

function ChartingState:getSectionBeats(section)
    if section == nil then section = self.curSection end
    local val = nil

    if self.__song.notes[section + 1] ~= nil then
        val = self.__song.notes[section + 1].sectionBeats
    end
    return val ~= nil and val or 4
end

function ChartingState:updateIcon()
    local function getIconFromCharacter(char)
        local charScript = paths.getJSON("data/characters/" .. char)
        local icon = charScript.healthicon
        return icon or 'bf'
    end
    local iconLeft = getIconFromCharacter(self.__song.player2)
    local iconRight = getIconFromCharacter(self.__song.player1)

    self.iconLeft.texture = paths.getImage('icons/icon-' .. iconLeft)
    self.iconRight.texture = paths.getImage('icons/icon-' .. iconRight)
end

function ChartingState:updateGrid()
    for i, spr in ipairs(self.curRenderedNotes.members) do spr:destroy() end
    self.curRenderedNotes:clear()

    if self.__song.notes[self.curSection + 1].changeBPM and
        self.__song.notes[self.curSection + 1].bpm > 0 then
        ChartingState.conductor:setBPM(self.__song.notes[self.curSection + 1]
                                           .bpm)
    else
        local daBpm = self.__song.bpm
        for i = 0, self.curSection do
            if self.__song.notes[i + 1].changeBPM then
                daBpm = self.__song.notes[i + 1].bpm
            end
        end
        ChartingState.conductor:setBPM(daBpm)
    end

    local beats = self:getSectionBeats()
    for _, i in ipairs(self.__song.notes[self.curSection + 1].sectionNotes) do
        local note = self:setupNote(i)
        self.curRenderedNotes:add(note)
        note.mustPress = self.__song.notes[self.curSection + 1].mustHitSection
        if i[2] > 3 then note.mustPress = not note.mustPress end
    end
end

function ChartingState:setupNote(i)
    local time = i[1]
    local data = i[2]
    local sus = i[3]

    local mustHit = self.__song.notes[self.curSection + 1].mustHitSection
    local dataPos = mustHit and {4, 5, 6, 7, 0, 1, 2, 3} or
                        {0, 1, 2, 3, 4, 5, 6, 7}

    local beats = self:getSectionBeats()

    local note = Note(time, data % 4)
    note.y = (self.gridSize * 20) +
                 self:getYfromStrumNote(time - self:sectionStartTime(), beats)
    note.x = math.floor(dataPos[data + 1] * self.gridSize) + self.gridSize +
                 (self.gridSize * 5)
    note:setGraphicSize(self.gridSize, self.gridSize)
    note:updateHitbox()

    return note
end

function ChartingState:addSection()
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

function ChartingState:leave()
    love.mouse.setVisible(false)

    game.sound.music:destroy()
    game.sound.music = nil

    Note.chartingMode = false
end

return ChartingState
