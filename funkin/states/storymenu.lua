local StoryMenuState = State:extend()

StoryMenuState.curWeek = 1

function StoryMenuState:enter()
    paths.clearCache()

    PlayState.storyMode = true

    self.scoreText = Text(10, 10, "SCORE: 49324858",
                             paths.getFont('vcr.ttf', 36), {1, 1, 1},
                             'right')

    self.txtWeekTitle = Text(game.width * 0.7, 10, "",
                             paths.getFont('vcr.ttf', 32), {1, 1, 1},
                             'right')
    self.txtWeekTitle.alpha = 0.7

    local bgYellow = Sprite(0, 56):make(game.width, 386, Color.fromRGB(249, 207, 81))

    self.grpWeekText = Group()
    self:add(self.grpWeekText)

    local blackBar = Sprite():make(game.width, 56, Color.BLACK)
    self:add(blackBar)

    self.groupCharacters = Group()

    local num = 0
    self.weekData = {}
    for _, weekStr in pairs(love.filesystem.getDirectoryItems(paths.getPath(
                                                              'data/weeks/weeks'))) do
        local data = paths.getJSON('data/weeks/weeks/' .. weekStr:withoutExt())

        local weekThing = MenuItem(0, bgYellow.y + bgYellow.height + 10, data.sprite)
        weekThing.y = weekThing.y + ((weekThing.height + 20) * num)
        weekThing.targetY = num
        self.grpWeekText:add(weekThing)

        weekThing:screenCenter("x")

        table.insert(self.weekData, data)
        num = num + 1
    end

    local charTable = self.weekData[StoryMenuState.curWeek].characters
    for char = 0, 2 do
        local weekCharThing = MenuCharacter((game.width * 0.25) * (1 + char) - 150,
                                             charTable[char+1])
        weekCharThing.y = weekCharThing.y + 70
        self.groupCharacters:add(weekCharThing)
    end

    self:add(bgYellow)
    self:add(self.groupCharacters)

    self.txtTrackList = Text(game.width * 0.05, bgYellow.x + bgYellow.height + 100,
                             "TRACKS", paths.getFont('vcr.ttf', 32),
                             Color.fromRGB(229, 87, 119), 'center')
    self:add(self.txtTrackList)
    self:add(self.scoreText)
    self:add(self.txtWeekTitle)

    self:changeWeek()

end

function StoryMenuState:update(dt)
    StoryMenuState.super.update(self, dt)

    if controls:pressed("ui_up") then
        self:changeWeek(-1)
    end
    if controls:pressed("ui_down") then
        self:changeWeek(1)
    end

    if controls:pressed("back") then
        game.sound.play(paths.getSound("cancelMenu"))
        game.switchState(MainMenuState())
    end
end

function StoryMenuState:changeWeek(change)
    if change == nil then change = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

    StoryMenuState.curWeek = StoryMenuState.curWeek + change

    if StoryMenuState.curWeek > #self.weekData then
        StoryMenuState.curWeek = 1
    elseif StoryMenuState.curWeek < 1 then
        StoryMenuState.curWeek = #self.weekData
    end

    local leWeek = self.weekData[StoryMenuState.curWeek]
    self.txtWeekTitle.content = leWeek.name:upper()
	self.txtWeekTitle.x = game.width - (self.txtWeekTitle:getWidth() + 10)

    local bullShit = 0

    for _, item in pairs(self.grpWeekText.members) do
        item.targetY = bullShit - (StoryMenuState.curWeek - 1)
        bullShit = bullShit + 1

        item.alpha = 0.6

        if item.targetY == 0 then item.alpha = 1 end
    end

    self:updateText()
end

function StoryMenuState:updateText()
    local weekTable = self.weekData[StoryMenuState.curWeek].characters
    for i = 1,#weekTable do
        self.groupCharacters.members[i]:changeCharacter(weekTable[i])
    end

    local leWeek = self.weekData[StoryMenuState.curWeek]
    local stringThing = {}
    for i = 1,#leWeek.songs do
        table.insert(stringThing, leWeek.songs[i][1])
    end

    self.txtTrackList.content = 'TRACKS\n'
    for i = 1,#stringThing do
        self.txtTrackList.content = self.txtTrackList.content .. '\n' .. stringThing[i]:upper()
    end

    self.txtTrackList:screenCenter("x")
    self.txtTrackList.x = self.txtTrackList.x - game.width * 0.35
end

return StoryMenuState