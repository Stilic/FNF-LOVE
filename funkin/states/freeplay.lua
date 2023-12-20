local json = require "lib.json".encode
local FreeplayState = State:extend("FreeplayState")

FreeplayState.curSelected = 1
FreeplayState.curDifficulty = 2

function FreeplayState:enter()
    -- Update Presence
    if love.system.getDevice() == "Desktop" then
        Discord.changePresence({details = "In the Menus"})
    end

    self.lerpScore = 0
    self.intendedScore = 0

    self.inSubstate = false

    self.persistentUpdate = true
    self.persistentDraw = true

    self.songsData = {}
    self:loadSongs()

    FreeplayState.curSelected = math.min(FreeplayState.curSelected, #self.songsData)

    self.bg = Sprite()
    self.bg:loadTexture(paths.getImage('menus/menuDesat'))
    self:add(self.bg)
    self.bg:screenCenter()
    if #self.songsData > 0 then
        self.bg.color = Color.fromString(self.songsData[FreeplayState.curSelected].color)
    end

    self.grpSongs = Group()
    self:add(self.grpSongs)

    self.noSongTxt = Alphabet(0, 0, 'No Songs Here', true, false)
    self.noSongTxt:screenCenter()
    self:add(self.noSongTxt)
    self.noSongTxt.visible = (#self.songsData == 0)

    self.iconTable = {}
    if #self.songsData > 0 then
        for i = 0, #self.songsData - 1 do
            local songText = Alphabet(0, (70 * i) + 30, self.songsData[i + 1].name,
                                      true, false)
            songText.isMenuItem = true
            songText.targetY = i
            self.grpSongs:add(songText)

            if songText:getWidth() > 980 then
                local textScale = 980 / songText:getWidth()
                songText.scale.x = textScale
                for _, letter in ipairs(songText.lettersArray) do
                    letter.x = letter.x * textScale
                    letter.offset.x = letter.offset.x * textScale
                end
            end

            local icon = HealthIcon(self.songsData[i + 1].icon)
            icon.sprTracker = songText
            icon:updateHitbox()

            table.insert(self.iconTable, icon)
            self:add(icon)
        end
    end

    self.scoreText = Text(game.width * 0.7, 5, "", paths.getFont("vcr.ttf", 32),
                            {1, 1, 1}, "right")
    self.scoreText.antialiasing = false

    self.scoreBG = Sprite(self.scoreText.x - 6, 0):make(1, 66, {0, 0, 0})
    self.scoreBG.alpha = 0.6
    self:add(self.scoreBG)

    self.diffText = Text(self.scoreText.x, self.scoreText.y + 36, "DIFFICULTY",
                            paths.getFont("vcr.ttf", 24))
    self.diffText.antialiasing = false
    self:add(self.diffText)
    self:add(self.scoreText)

    if #self.songsData > 0 then self:changeSelection() end

    if love.system.getDevice() == "Mobile" then
        self.buttons = ButtonGroup()
        self.buttons.type = "roundrect"
        self.buttons.lined = true
        self.buttons.width = 134
        self.buttons.height = 134

        local w = self.buttons.width

        local left = Button(2, game.height - w, 0, 0, "left")
        local up = Button(left.x + w, left.y - w, 0, 0, "up")
        local down = Button(up.x, left.y, 0, 0, "down")
        local right = Button(down.x + w, left.y, 0, 0, "right")

        local enter = Button(game.width - w, left.y, 0, 0, "return")
        enter:setColor(Color.GREEN)
        local back = Button(enter.x - w, left.y, 0, 0, "escape")
        back:setColor(Color.RED)

        self.buttons:add(left)
        self.buttons:add(up)
        self.buttons:add(down)
        self.buttons:add(right)

        self.buttons:add(enter)
        self.buttons:add(back)

        self:add(self.buttons)
        game.buttons.add(self.buttons)
    end
end

function FreeplayState:update(dt)
    self.lerpScore = util.coolLerp(self.lerpScore, self.intendedScore, 0.4)
    self.scoreText.content = "PERSONAL BEST: " .. math.floor(self.lerpScore)

    self:positionHighscore()

    if not self.inSubstate then
        if #self.songsData > 0 then
            if controls:pressed('ui_up') then self:changeSelection(-1) end
            if controls:pressed('ui_down') then self:changeSelection(1) end
            if controls:pressed('ui_left') then self:changeDiff(-1) end
            if controls:pressed('ui_right') then self:changeDiff(1) end

            if controls:pressed('accept') then
                local daSong = paths.formatToSongPath(self.songsData[FreeplayState.
                                                        curSelected].name)
                PlayState.storyMode = false
                local songdiffs = self.songsData[self.curSelected].difficulties
                local diff = ""
                if songdiffs[FreeplayState.curDifficulty] ~= "Normal" then
                    diff = songdiffs[FreeplayState.curDifficulty]:lower()
                end

                if self:checkSongDifficulty() then
                    if Keyboard.pressed.SHIFT then
                        PlayState.loadSong(daSong, diff)
                        PlayState.storyDifficulty = diff
                        game.switchState(ChartingState())
                    else
                        game.switchState(PlayState(false, daSong, diff))
                    end
                else
                    local suffix = (diff ~= "" and "-" .. diff or "")
                    local path = 'songs/' .. daSong .. '/chart' .. suffix .. '.json'
                    self.inSubstate = true
                    self:openSubstate(ChartErrorSubstate(path))
                end
            end
        end
        if controls:pressed("back") then
            game.sound.play(paths.getSound('cancelMenu'))
            game.switchState(MainMenuState())
        end
    end

    if #self.songsData > 0 then
        local colorBG = Color.fromString(self.songsData[FreeplayState.curSelected].color)
        self.bg.color[1] = util.coolLerp(self.bg.color[1], colorBG[1], 0.05)
        self.bg.color[2] = util.coolLerp(self.bg.color[2], colorBG[2], 0.05)
        self.bg.color[3] = util.coolLerp(self.bg.color[3], colorBG[3], 0.05)
    end

    FreeplayState.super.update(self, dt)
end

function FreeplayState:closeSubstate()
    self.inSubstate = false
    FreeplayState.super.closeSubstate(self)
end

function FreeplayState:changeDiff(change, playsound)
    if change == nil then change = 0 end
    if playsound == nil then playsound = true end
    local songdiffs = self.songsData[self.curSelected].difficulties

    FreeplayState.curDifficulty = FreeplayState.curDifficulty + change

    if FreeplayState.curDifficulty > #songdiffs then
        FreeplayState.curDifficulty = 1
    elseif FreeplayState.curDifficulty < 1 then
        FreeplayState.curDifficulty = #songdiffs
    end

    local diff = ""
    if songdiffs[FreeplayState.curDifficulty] ~= "Normal" then
        diff = songdiffs[FreeplayState.curDifficulty]:lower()
    end

    local daSong = paths.formatToSongPath(self.songsData[self.curSelected].name)
    self.intendedScore = Highscore.getScore(daSong, diff)

    if #songdiffs > 1 then
        self.diffText.content = "< " .. songdiffs[FreeplayState.curDifficulty]:upper() .. " >"
        if playsound then
            game.sound.play(paths.getSound('scrollMenu'))
        end
    else
        self.diffText.content = songdiffs[FreeplayState.curDifficulty]:upper()
    end
    self:positionHighscore()
end

function FreeplayState:changeSelection(change)
    if change == nil then change = 0 end

    FreeplayState.curSelected = FreeplayState.curSelected + change

    if FreeplayState.curSelected > #self.songsData then
        FreeplayState.curSelected = 1
    elseif FreeplayState.curSelected < 1 then
        FreeplayState.curSelected = #self.songsData
    end

    local bullShit = 0

    for _, item in pairs(self.grpSongs.members) do
        item.targetY = bullShit - (FreeplayState.curSelected - 1)
        bullShit = bullShit + 1

        item.alpha = 0.6

        if item.targetY == 0 then item.alpha = 1 end
    end

    for _, icon in next, self.iconTable do icon.alpha = 0.6 end
    self.iconTable[FreeplayState.curSelected].alpha = 1

    if #self.songsData > 1 then
        game.sound.play(paths.getSound('scrollMenu'))
    end

    self:changeDiff(0, false)
end

function FreeplayState:positionHighscore()
    self.scoreText.x = game.width - self.scoreText:getWidth() - 6
    self.scoreBG.width = self.scoreText:getWidth() + 12
    self.scoreBG.x = self.scoreText.x + (self.scoreBG.width / 2) - 6
    self.diffText.x = math.floor(self.scoreBG.x)
    self.diffText.x = self.diffText.x - self.diffText:getWidth() / 2
end

function FreeplayState:checkSongDifficulty()
    local song = paths.formatToSongPath(self.songsData[self.curSelected].name)
    local songdiffs = self.songsData[self.curSelected].difficulties
    local diff = ""
    if songdiffs[FreeplayState.curDifficulty] ~= "Normal" then
        diff = "-" .. songdiffs[FreeplayState.curDifficulty]:lower()
    end
    if paths.getJSON('songs/'..song..'/chart'..diff) then
        return true
    end
    return false
end

local function getSongMetadata(song)
    local songformat = paths.formatToSongPath(song)
    local song_metadata = paths.getJSON('songs/'..songformat..'/meta')
    local metadata = {
        name = song_metadata.name or 'Name',
        icon = song_metadata.icon or 'face',
        color = song_metadata.color or '#0F0F0F',
        difficulties = song_metadata.difficulties or {'Easy', 'Normal', 'Hard'}
    }
    return metadata
end

function FreeplayState:loadSongs()
    if Mods.currentMod then
        if paths.exists(paths.getMods('data/freeplayList.txt'), 'file') then
            local listData = paths.getText('freeplayList'):gsub('\r',''):split('\n')
            for _, song in pairs(listData) do
                table.insert(self.songsData, getSongMetadata(song))
            end
        else
            if paths.exists(paths.getMods('data/weekList.txt'), 'file') then
                local listData = paths.getText('weekList'):gsub('\r',''):split('\n')
                for _, week in pairs(listData) do
                    local weekData = paths.getJSON('data/weeks/weeks/'..week)
                    for _, song in ipairs(weekData.songs) do
                        table.insert(self.songsData, getSongMetadata(song))
                    end
                end
            else
                for _, str in pairs(love.filesystem.getDirectoryItems(paths.getMods(
                                                                  'data/weeks/weeks'))) do
                    local weekName = str:withoutExt()
                    if str:endsWith('.json') then
                        local weekData = paths.getJSON('data/weeks/weeks/'..weekName)
                        for _, song in ipairs(weekData.songs) do
                            table.insert(self.songsData, getSongMetadata(song))
                        end
                    end
                end
            end
        end
    else
        if paths.exists(paths.getPath('data/freeplayList.txt'), 'file') then
            local listData = paths.getText('freeplayList'):gsub('\r',''):split('\n')
            for _, song in pairs(listData) do
                table.insert(self.songsData, getSongMetadata(song))
            end
        else
            if paths.exists(paths.getPath('data/weekList.txt'), 'file') then
                local listData = paths.getText('weekList'):gsub('\r',''):split('\n')
                for _, week in pairs(listData) do
                    local weekData = paths.getJSON('data/weeks/weeks/'..week)
                    for _, song in ipairs(weekData.songs) do
                        table.insert(self.songsData, getSongMetadata(song))
                    end
                end
            else
                for _, str in pairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                                  'data/weeks/weeks'))) do
                    local weekName = str:withoutExt()
                    if str:endsWith('.json') then
                        local weekData = paths.getJSON('data/weeks/weeks/'..weekName)
                        for _, song in ipairs(weekData.songs) do
                            table.insert(self.songsData, getSongMetadata(song))
                        end
                    end
                end
            end
        end
    end
end

return FreeplayState
