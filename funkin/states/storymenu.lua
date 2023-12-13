local StoryMenuState = State:extend("StoryMenuState")

StoryMenuState.curWeek = 1
StoryMenuState.curDifficulty = 2

function StoryMenuState:enter()
    -- Update Presence
    if love.system.getDevice() == "Desktop" then
        Discord.changePresence({details = "In the Menus"})
    end

    self.lerpScore = 0
    self.intendedScore = 0

    self.inSubstate = false

    self.persistentUpdate = true
    self.persistentDraw = true

    self.movedBack = false
    self.selectedWeek = false

    PlayState.storyMode = true

    self.scoreText = Text(10, 10, "SCORE: 49324858",
                          paths.getFont('vcr.ttf', 36), {1, 1, 1}, 'right')

    self.txtWeekTitle = Text(game.width * 0.7, 10, "",
                             paths.getFont('vcr.ttf', 32), {1, 1, 1}, 'right')
    self.txtWeekTitle.alpha = 0.7

    local ui_tex = paths.getSparrowAtlas(
                       'menus/storymenu/campaign_menu_UI_assets');
    local bgYellow = Graphic(0, 56, game.width, 386, Color.fromRGB(249, 207, 81))

    self.grpWeekText = Group()
    self:add(self.grpWeekText)

    local blackBar = Graphic(0, 0, game.width, 56, Color.BLACK)
    self:add(blackBar)

    self.grpWeekCharacters = Group()

    self.grpLocks = Group()
    self:add(self.grpLocks)

    self.weeksData = {}
    self:loadWeeks()
    for i, week in pairs(self.weeksData) do
        local isLocked = (week.locked == true)
        local weekThing = MenuItem(0, bgYellow.y + bgYellow.height + 10,
                                    week.sprite)
        weekThing.y = weekThing.y + ((weekThing.height + 20) * (i - 1))
        weekThing.targetY = num
        self.grpWeekText:add(weekThing)

        weekThing:screenCenter("x")

        if isLocked then
            local lock = Sprite(weekThing.width + 10 + weekThing.x)
            lock:setFrames(ui_tex)
            lock:addAnimByPrefix('lock', 'lock')
            lock:play('lock')
            lock.ID = i
            self.grpLocks:add(lock)
        end
    end

    local charTable = self.weeksData[StoryMenuState.curWeek].characters
    for char = 0, 2 do
        local weekCharThing = MenuCharacter(
                                  (game.width * 0.25) * (1 + char) - 150,
                                  charTable[char + 1])
        weekCharThing.y = weekCharThing.y + 70
        self.grpWeekCharacters:add(weekCharThing)
    end

    self.difficultySelector = Group()
    self:add(self.difficultySelector)

    self.leftArrow = Sprite(self.grpWeekText.members[1].x +
                                self.grpWeekText.members[1].width + 10,
                            self.grpWeekText.members[1].y + 10);
    self.leftArrow:setFrames(ui_tex)
    self.leftArrow:addAnimByPrefix('idle', "arrow left")
    self.leftArrow:addAnimByPrefix('press', "arrow push left")
    self.leftArrow:play('idle')
    self.difficultySelector:add(self.leftArrow)

    self.sprDifficulty = Sprite(0, self.leftArrow.y);
    self.difficultySelector:add(self.sprDifficulty);

    self.rightArrow = Sprite(self.leftArrow.x + 376, self.leftArrow.y);
    self.rightArrow:setFrames(ui_tex)
    self.rightArrow:addAnimByPrefix('idle', "arrow right")
    self.rightArrow:addAnimByPrefix('press', "arrow push right")
    self.rightArrow:play('idle')
    self.difficultySelector:add(self.rightArrow)

    self:add(bgYellow)
    self:add(self.grpWeekCharacters)

    self.txtTrackList = Text(game.width * 0.05,
                             bgYellow.x + bgYellow.height + 100, "TRACKS",
                             paths.getFont('vcr.ttf', 32),
                             Color.fromRGB(229, 87, 119), 'center')
    self:add(self.txtTrackList)
    self:add(self.scoreText)
    self:add(self.txtWeekTitle)

    self:changeWeek()
    self:changeDifficulty()
end

local tweenDifficulty = Timer.new()
function StoryMenuState:update(dt)
    self.lerpScore = util.coolLerp(self.lerpScore, self.intendedScore, 0.5)
    self.scoreText.content = 'WEEK SCORE:' .. math.round(self.lerpScore)

    if not self.movedBack and not self.selectedWeek and not self.inSubstate then
        if controls:pressed("ui_up") then self:changeWeek(-1) end
        if controls:pressed("ui_down") then self:changeWeek(1) end

        if controls:down("ui_left") then
            self.leftArrow:play('press')
        else
            self.leftArrow:play('idle')
        end
        if controls:down("ui_right") then
            self.rightArrow:play('press')
        else
            self.rightArrow:play('idle')
        end

        if controls:pressed("ui_left") then self:changeDifficulty(-1) end
        if controls:pressed("ui_right") then self:changeDifficulty(1) end

        if controls:pressed("accept") then self:selectWeek() end
    end

    if controls:pressed("back") and not self.movedBack and not self.selectedWeek
        and not self.inSubstate then
        game.sound.play(paths.getSound("cancelMenu"))
        self.movedBack = true
        game.switchState(MainMenuState())
    end

    StoryMenuState.super.update(self, dt)

    tweenDifficulty:update(dt)

    for _, lock in pairs(self.grpLocks.members) do
        lock.y = self.grpWeekText.members[lock.ID].y
        lock.visible = (lock.y > game.height / 2)
    end
end

function StoryMenuState:selectWeek()
    if not self.weeksData[StoryMenuState.curWeek].locked then
        local songTable = {}
        local leWeek = self.weeksData[StoryMenuState.curWeek]
        for i = 1, #leWeek.songs do
            table.insert(songTable, paths.formatToSongPath(leWeek.songs[i]))
        end

        local diff = ""
        switch(StoryMenuState.curDifficulty, {
            [1] = function() diff = "easy" end,
            [3] = function() diff = "hard" end
        })

        if self:checkSongsDifficulty() then
            local toState = PlayState(true, songTable, diff)
            PlayState.storyWeek = leWeek.name
            PlayState.storyWeekFile = leWeek.file

            if not self.selectedWeek then
                game.sound.play(paths.getSound('confirmMenu'))
                self.grpWeekText.members[StoryMenuState.curWeek]:startFlashing()
                for _, char in pairs(self.grpWeekCharacters.members) do
                    if char.character ~= '' and char.hasConfirmAnimation then
                        char:play('confirm')
                    end
                end
                self.selectedWeek = true
            end

            Timer.after(1, function() game.switchState(toState) end)
        else
            local pathTable = {}
            for i = 1, #songTable do
                local suffix = (diff ~= "" and "-" .. diff or "")
                local path = 'songs/' .. songTable[i] .. '/chart' .. suffix
                if not paths.getJSON(path) then
                    table.insert(pathTable, path .. '.json')
                end
            end
            self.inSubstate = true
            self:openSubstate(ChartErrorSubstate(pathTable))
        end
    else
        game.sound.play(paths.getSound('cancelMenu'))
    end
end

local diffString = {'Easy', 'Normal', 'Hard'}

function StoryMenuState:changeDifficulty(change)
    if change == nil then change = 0 end

    StoryMenuState.curDifficulty = StoryMenuState.curDifficulty + change

    if StoryMenuState.curDifficulty > 3 then
        StoryMenuState.curDifficulty = 1
    elseif StoryMenuState.curDifficulty < 1 then
        StoryMenuState.curDifficulty = 3
    end

    local storyDiff = diffString[StoryMenuState.curDifficulty]
    local newImage = paths.getImage('menus/storymenu/difficulties/' ..
                                        paths.formatToSongPath(storyDiff))

    if self.sprDifficulty.texture ~= newImage then
        self.sprDifficulty:loadTexture(newImage)
        self.sprDifficulty.x = self.leftArrow.x + 60
        self.sprDifficulty.x = self.sprDifficulty.x +
                                   ((308 - self.sprDifficulty.width) / 3)
        self.sprDifficulty.alpha = 0
        self.sprDifficulty.y = self.leftArrow.y - 15

        Timer:cancelTweensOf(tweenDifficulty)
        tweenDifficulty:tween(0.07, self.sprDifficulty,
                              {y = self.leftArrow.y + 15, alpha = 1})
    end

    local diff = ""
    switch(StoryMenuState.curDifficulty, {
        [1] = function() diff = "easy" end,
        [3] = function() diff = "hard" end
    })

    local weekName = self.weeksData[StoryMenuState.curWeek].file
    self.intendedScore = Highscore.getWeekScore(weekName, diff)
end

function StoryMenuState:changeWeek(change)
    if change == nil then change = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

    StoryMenuState.curWeek = StoryMenuState.curWeek + change

    if StoryMenuState.curWeek > #self.weeksData then
        StoryMenuState.curWeek = 1
    elseif StoryMenuState.curWeek < 1 then
        StoryMenuState.curWeek = #self.weeksData
    end

    local leWeek = self.weeksData[StoryMenuState.curWeek]
    self.txtWeekTitle.content = leWeek.name:upper()
    self.txtWeekTitle.x = game.width - (self.txtWeekTitle:getWidth() + 10)

    local bullShit = 0

    for _, item in pairs(self.grpWeekText.members) do
        item.targetY = bullShit - (StoryMenuState.curWeek - 1)
        bullShit = bullShit + 1

        item.alpha = 0.6

        if item.targetY == 0 then item.alpha = 1 end
    end

    for _, spr in pairs(self.difficultySelector.members) do
        spr.visible = not leWeek.locked
    end

    self:updateText()
end

function StoryMenuState:updateText()
    local weekTable = self.weeksData[StoryMenuState.curWeek].characters
    for i = 1, #weekTable do
        self.grpWeekCharacters.members[i]:changeCharacter(weekTable[i])
    end

    local leWeek = self.weeksData[StoryMenuState.curWeek]
    local stringThing = {}
    for i = 1, #leWeek.songs do table.insert(stringThing, leWeek.songs[i]) end

    self.txtTrackList.content = 'TRACKS\n'
    for i = 1, #stringThing do
        self.txtTrackList.content = self.txtTrackList.content .. '\n' ..
                                        stringThing[i]:upper()
    end

    self.txtTrackList:screenCenter("x")
    self.txtTrackList.x = self.txtTrackList.x - game.width * 0.35

    local diff = ""
    switch(StoryMenuState.curDifficulty, {
        [1] = function() diff = "easy" end,
        [3] = function() diff = "hard" end
    })

    local weekName = self.weeksData[StoryMenuState.curWeek].file
    self.intendedScore = Highscore.getWeekScore(weekName, diff)
end

function StoryMenuState:closeSubstate()
    self.inSubstate = false
    StoryMenuState.super.closeSubstate(self)
end

function StoryMenuState:checkSongsDifficulty()
    local weekSongs = self.weeksData[StoryMenuState.curWeek].songs
    local diff = ""
    if diffString[StoryMenuState.curDifficulty] ~= "Normal" then
        diff = "-" .. diffString[StoryMenuState.curDifficulty]:lower()
    end
    local checkSongs = {}
    for _, s in ipairs(weekSongs) do
        local song = paths.formatToSongPath(s)
        if paths.getJSON('songs/'..song..'/chart'..diff) then
            table.insert(checkSongs, true)
        else
            table.insert(checkSongs, false)
        end
    end
    if table.find(checkSongs, false) then return false
    else return true end
    return false
end

function StoryMenuState:loadWeeks()
    if paths.exists(paths.getPath('data/weekList.txt'), 'file') then
        local listData = paths.getText('weekList'):gsub('\r',''):split('\n')
        for _, week in pairs(listData) do
            local data = paths.getJSON('data/weeks/weeks/'..week)
            data.file = week
            table.insert(self.weeksData, data)
        end
    else
        for _, str in pairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                          'data/weeks/weeks'))) do
            local week = str:withoutExt()
            if str:endsWith('.json') then
                local data = paths.getJSON('data/weeks/weeks/'..week)
                data.file = week
                table.insert(self.weeksData, data)
            end
        end
    end
end

return StoryMenuState
