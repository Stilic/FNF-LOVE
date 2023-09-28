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
            song = 'Cutcorners',
            bpm = 142.0,
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

    self.gridSize = 40
    self.uiGrid = ui.UIGrid(self.gridSize * 6, 0, 64, 8, self.gridSize,
                            {1, 1, 1}, {0.7, 0.7, 0.7})
    self.uiGrid_highlight = ui.UIGrid(0, 0, 16, 2, self.gridSize * 4,
                                      {0, 0, 0, 0}, {0, 0, 0, 0.5})

    self:add(self.uiGrid)
    self:add(self.uiGrid_highlight)

    local daBlack = Sprite(self.uiGrid.x, 0)
    daBlack:setScrollFactor()
    daBlack:make(self.gridSize * 8, (self.gridSize * 4), {0, 0, 0})
    daBlack.alpha = 0.4
    self:add(daBlack)

    self.iconLeft = HealthIcon('dad')
    self.iconLeft.x, self.iconLeft.y = self.uiGrid.x + (self.gridSize + 5),
                                       self.gridSize - 35
    self.iconLeft:setScrollFactor()
    self.iconLeft:swap(1)

    self.iconRight = HealthIcon('bf')
    self.iconRight.x, self.iconRight.y =
        self.uiGrid.x + (self.gridSize * 5) + 5, self.gridSize - 35
    self.iconRight:setScrollFactor()
    self.iconRight:swap(1)

    self.iconLeft:setGraphicSize(0, 80)
    self.iconRight:setGraphicSize(0, 80)

    self:add(self.iconLeft)
    self:add(self.iconRight)

    loadSong(self, self.__song.song)

    updateIcon(self)

    self.blockInput = {}
    self.isTyping = false

    self.dummyArrow = Sprite()
    self.dummyArrow:make(self.gridSize, self.gridSize, {1, 1, 1})
    self:add(self.dummyArrow)

    self.curRenderedNotes = Group()
    self:add(self.curRenderedNotes)

    -- updateGrid(self)

    local tabs = {"Charting", "Events", "Note", "Section", "Song"}
    self.UI_Box = ui.UITabMenu(890, 40, tabs)
    self.UI_Box.height = (push.getHeight() - self.UI_Box.tabHeight) -
                             (self.UI_Box.y * 2)

    self:add(self.UI_Box)
    self:add_UI_Song()
end

function ChartingState:add_UI_Song()

    local input_song = ui.UIInputTextBox(45, 10, 135, 20)
    input_song.text = self.__song.song
    input_song.onChanged = function(value) self.__song.song = value end

    local load_audio_button = ui.UIButton(300, 10, 80, 20, 'Load Audio',
                                          function()
        loadSong(self, input_song.text)
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
        ChartingState.inst:setBPM(value)
    end

    local speed_stepper = ui.UINumericStepper(10, 160, 0.1, self.__song.speed,
                                              0.1, 10)
    speed_stepper.onChanged = function(value) self.__song.speed = value end

    local optionsChar = {
        "bf", "dad", "gf", "senpai", "senpai-angry", "spirit", "bf-pixel",
        "gf-pixel", "tankman", "bf-holding-gf", "gf-tankmen", "pico-speaker",
        "ralt-gf"
    }
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
    girlfriend_dropdown.onChanged = function(value)
        self.__song.gfVersion = value
    end

    local optionsStage = {"stage", "school", "tank"}
    local stage_dropdown = ui.UIDropDown(140, 210, optionsStage)
    stage_dropdown.selectedLabel = self.__song.stage
    stage_dropdown.onChanged = function(value) self.__song.stage = value end

    local tab_song_test = Group()
    tab_song_test.name = "Song"

    table.insert(self.blockInput, input_song)
    table.insert(self.blockInput, bpm_stepper)
    table.insert(self.blockInput, speed_stepper)

    tab_song_test:add(ui.UIText(4, 10, "Song:"))
    tab_song_test:add(input_song)
    tab_song_test:add(ui.UIText(34, 43, "Has voice track"))
    tab_song_test:add(voice_track)
    tab_song_test:add(ui.UIText(10, 80, "Song BPM:"))
    tab_song_test:add(bpm_stepper)
    tab_song_test:add(ui.UIText(10, 140, "Song Speed:"))
    tab_song_test:add(speed_stepper)
    tab_song_test:add(load_audio_button)
    tab_song_test:add(save_song_button)
    tab_song_test:add(ui.UIText(10, 310, "Girlfriend:"))
    tab_song_test:add(girlfriend_dropdown)
    tab_song_test:add(ui.UIText(10, 250, "Opponent:"))
    tab_song_test:add(opponent_dropdown)
    tab_song_test:add(ui.UIText(10, 190, "Boyfriend:"))
    tab_song_test:add(boyfriend_dropdown)
    tab_song_test:add(stage_dropdown)

    self.UI_Box:addGroup(tab_song_test)
end

function ChartingState:update(dt)
    for _, inputObj in ipairs(self.blockInput) do
        if inputObj.active then
            self.isTyping = true
            break
        end
        self.isTyping = false
    end

    self.uiGrid_highlight.y = self.uiGrid.y
    self.uiGrid_highlight.x = self.uiGrid.x

    ChartingState.songPosition = ChartingState.inst.sound:tell() * 1000
    strumLineUpdateY(self)

    if Mouse.x > self.uiGrid.x and Mouse.x < self.uiGrid.x + self.uiGrid.width and
        Mouse.y > (self.gridSize * 4) and Mouse.y < self.uiGrid.y +
        (self.gridSize * 4 * 4) then
        self.dummyArrow.visible = true
        self.dummyArrow.x = math.floor(Mouse.x / self.gridSize) * self.gridSize
        if Keyboard.pressed.SHIFT then
            self.dummyArrow.y = Mouse.y
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

    if not self.isTyping then

        if Mouse.justPressed then
            if Mouse.overlaps() then
                --
            else
                if Mouse.x > self.uiGrid.x and Mouse.x < self.uiGrid.x +
                    self.uiGrid.width and Mouse.y > (self.gridSize * 4) and
                    Mouse.y < self.uiGrid.y + (self.gridSize * 4 * 4) then

                    -- print('added note')
                end
            end
        end

        if Keyboard.justPressed.SPACE then
            if ChartingState.inst.sound:isPlaying() then
                ChartingState.inst:pause()
                if ChartingState.vocals then
                    ChartingState.vocals:pause()
                end
            else
                if ChartingState.vocals then
                    ChartingState.vocals:seek(ChartingState.inst.sound:tell())
                    ChartingState.vocals:play()
                end
                ChartingState.inst:play()
            end
        end

        if Keyboard.pressed.W or Keyboard.pressed.S then
            ChartingState.inst:pause()

            local shiftMult = 1
            if Keyboard.pressed.CONTROL then
                shiftMult = 0.25
            elseif Keyboard.pressed.SHIFT then
                shiftMult = 4
            end

            local daTime = 700 * dt * shiftMult

            if Keyboard.pressed.W then
                local checkTime = ChartingState.inst.sound:tell() -
                                      (daTime / 1000)
                if checkTime > 0 then
                    ChartingState.inst.sound:seek(
                        ChartingState.inst.sound:tell() - (daTime / 1000))
                end
            else
                local checkLimit = ChartingState.inst.sound:tell() +
                                       (daTime / 1000)
                if checkLimit < ChartingState.inst.sound:getDuration() then
                    ChartingState.inst.sound:seek(
                        ChartingState.inst.sound:tell() + (daTime / 1000))
                else
                    ChartingState.inst.sound:seek(0)
                end
            end

            if ChartingState.vocals then
                ChartingState.vocals:pause()
                ChartingState.vocals:seek(ChartingState.inst.sound:tell())
            end

            ChartingState.inst:__updateTime()
        end

        if Keyboard.justPressed.ENTER then
            ChartingState.inst:pause()
            if ChartingState.vocals then ChartingState.vocals:pause() end

            switchState(PlayState())
        end
    end

    ChartingState.songPosition = ChartingState.inst.sound:tell() * 1000
    strumLineUpdateY(self)

    ChartingState.super.update(self, dt)
end

function loadSong(self, song)
    if ChartingState.inst then ChartingState.inst:destroy() end
    ChartingState.inst = Conductor(game.sound.load(paths.getInst(song)),
                                   self.__song.bpm)
    ChartingState.inst.sound:setLooping(true)
    ChartingState.inst.onBeat = function(b)
        local tick = game.sound.play(paths.getSound('metronome'))
        tick:setPitch(b % 4 == 0 and 1.1 or 1)
    end
    if self.__song.needsVoices then
        ChartingState.vocals = paths.getVoices(song)
        if ChartingState.vocals then
            ChartingState.vocals:setLooping(true)
        end
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

function strumLineUpdateY(self)
    local function getYfromStrum(strumTime)
        local offset = (self.gridSize * 13)
        return math.remapToRange(strumTime, 0,
                                 16 * ChartingState.inst.stepCrochet,
                                 self.uiGrid.y + offset, self.uiGrid.y +
                                     (self.uiGrid.height / 4) + offset)
    end
    self.camScroll.target.y = getYfromStrum(
                                  (ChartingState.songPosition) / 1 %
                                      (ChartingState.inst.stepCrochet * 16)) /
                                  (4 / 4)
end

function updateIcon(self)
    local iconLeft = getIconFromCharacter(self.__song.player2)
    local iconRight = getIconFromCharacter(self.__song.player1)

    self.iconLeft.texture = paths.getImage('icons/icon-' .. iconLeft)
    self.iconRight.texture = paths.getImage('icons/icon-' .. iconRight)
end

function getIconFromCharacter(char)
    local daIconShit = Character(0, 0, char).icon
    return daIconShit
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

function setupNote(self, i)
    local time = i[1]
    local data = i[2]
    local sus = i[3]

    local note = Note(time, data % 4)
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

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", (self.gridSize * 10) - 1, 0, 2,
                            push:getHeight())

    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", self.uiGrid.x, (self.gridSize * 4) - 1,
                            self.gridSize * 8, 2)

    love.graphics.setColor(1, 1, 1)
    local daText = util.floorDecimal(ChartingState.songPosition / 1000, 2) ..
                       ' / ' ..
                       util.floorDecimal(
                           ChartingState.inst.sound:getDuration(), 2) ..
                       '\nSection: ' ..
                       math.floor(ChartingState.inst.currentStep / 16) ..
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

    ChartingState.inst:destroy()
    ChartingState.inst = nil
    ChartingState.vocals = nil
end

return ChartingState
