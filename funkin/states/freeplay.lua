local FreeplayState = State:extend()

FreeplayState.curSelected = 1
FreeplayState.curDifficulty = 2

function FreeplayState:enter()
    -- Update Presence
    if love.system.getDevice() == "Desktop" then
        Discord.changePresence({details = "In the Menus"})
    end

    self.lerpScore = 0
    self.intendedScore = 0

    self.songsData = {}
    for _, weekStr in pairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                                  'data/weeks/weeks'))) do
        local data = paths.getJSON('data/weeks/weeks/' .. weekStr:withoutExt())
        if not data.locked then
            for _, song in pairs(data.songs) do
                table.insert(self.songsData, song)
            end
        end
    end

    self.bg = Sprite()
    self.bg:loadTexture(paths.getImage('menus/menuDesat'))
    self:add(self.bg)
    self.bg:screenCenter()

    -- SHITTY STUFF :(
    self.bg.color = Color.convert(self.songsData[FreeplayState.curSelected][3])

    self.grpSongs = Group()
    self:add(self.grpSongs)

    self.iconTable = {}
    for i = 0, #self.songsData - 1 do
        local songText = Alphabet(0, (70 * i) + 30, self.songsData[i + 1][1],
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

        local icon = HealthIcon(self.songsData[i + 1][2])
        icon.sprTracker = songText

        table.insert(self.iconTable, icon)
        self:add(icon)
    end

    self.scoreText = Text(game.width * 0.7, 5, "", paths.getFont("vcr.ttf", 32),
                            {1, 1, 1}, "right")

    self.scoreBG = Sprite(self.scoreText.x - 6, 0):make(1, 66, {0, 0, 0})
    self.scoreBG.alpha = 0.6
    self:add(self.scoreBG)

    self.diffText = Text(self.scoreText.x, self.scoreText.y + 36, "",
                            paths.getFont("vcr.ttf", 24))
    self:add(self.diffText)
    self:add(self.scoreText)

    self:changeSelection()
end

function FreeplayState:update(dt)
    self.lerpScore = util.coolLerp(self.lerpScore, self.intendedScore, 0.4)
    self.scoreText.content = "PERSONAL BEST: " .. math.floor(self.lerpScore)

    self:positionHighscore()

    if controls:pressed('ui_up') then self:changeSelection(-1) end
    if controls:pressed('ui_down') then self:changeSelection(1) end
    if controls:pressed('ui_left') then self:changeDiff(-1) end
    if controls:pressed('ui_right') then self:changeDiff(1) end

    if controls:pressed("back") then
        game.sound.play(paths.getSound('cancelMenu'))
        game.switchState(MainMenuState())
    end
    if controls:pressed('accept') then
        local daSong = paths.formatToSongPath(self.songsData[FreeplayState.curSelected][1])
        PlayState.storyMode = false

        local diff = ""
        switch(FreeplayState.curDifficulty, {
            [1] = function() diff = "easy" end,
            [3] = function() diff = "hard" end
        })

        game.switchState(PlayState(false, daSong, diff))
    end

    -- SHITTY STUFF :(
    local colorBG = Color.convert(self.songsData[FreeplayState.curSelected][3])
    self.bg.color[1] = util.coolLerp(self.bg.color[1], colorBG[1], 0.05)
    self.bg.color[2] = util.coolLerp(self.bg.color[2], colorBG[2], 0.05)
    self.bg.color[3] = util.coolLerp(self.bg.color[3], colorBG[3], 0.05)

    FreeplayState.super.update(self, dt)
end

local diffString = {'Easy', 'Normal', 'Hard'}

function FreeplayState:changeDiff(change)
    if change == nil then change = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

    FreeplayState.curDifficulty = FreeplayState.curDifficulty + change

    if FreeplayState.curDifficulty > 3 then
        FreeplayState.curDifficulty = 1
    elseif FreeplayState.curDifficulty < 1 then
        FreeplayState.curDifficulty = 3
    end

    local diff = ""
    switch(FreeplayState.curDifficulty, {
        [1] = function() diff = "easy" end,
        [3] = function() diff = "hard" end
    })

    local daSong = paths.formatToSongPath(self.songsData[self.curSelected][1])
    self.intendedScore = Highscore.getScore(daSong, diff)

    self.diffText.content = "< " .. diffString[FreeplayState.curDifficulty]:upper() .. " >"
    self:positionHighscore()
end

function FreeplayState:changeSelection(change)
    if change == nil then change = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

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

    for _, icon in pairs(self.iconTable) do icon.alpha = 0.6 end
    self.iconTable[FreeplayState.curSelected].alpha = 1

    self:changeDiff()
end

function FreeplayState:positionHighscore()
    self.scoreText.x = game.width - self.scoreText:getWidth() - 6
    self.scoreBG.width = self.scoreText:getWidth() + 12
    self.scoreBG.x = self.scoreText.x + (self.scoreBG.width / 2) - 6
    self.diffText.x = math.floor(self.scoreBG.x)
    self.diffText.x = self.diffText.x - self.diffText:getWidth() / 2
end

return FreeplayState
