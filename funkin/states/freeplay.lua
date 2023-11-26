local FreeplayState = State:extend()

FreeplayState.curSelected = 1

function FreeplayState:enter()
    -- Update Presence
    if love.system.getDevice() == "Desktop" then
        Discord.changePresence({details = "In the Menus"})
    end

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
    local colorBG = Color.fromRGB(
                        self.songsData[FreeplayState.curSelected][3][1],
                        self.songsData[FreeplayState.curSelected][3][2],
                        self.songsData[FreeplayState.curSelected][3][3])
    self.bg.color = colorBG

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

    self:changeSelection()
end

function FreeplayState:update(dt)
    if controls:pressed('ui_up') then self:changeSelection(-1) end
    if controls:pressed('ui_down') then self:changeSelection(1) end

    if controls:pressed("back") then
        game.sound.play(paths.getSound('cancelMenu'))
        game.switchState(MainMenuState())
    end
    if controls:pressed('accept') then
        local daSong = paths.formatToSongPath(self.songsData[FreeplayState.curSelected][1])
        PlayState.storyMode = false
        game.switchState(PlayState(daSong))
    end

    -- SHITTY STUFF :(
    local colorBG = Color.fromRGB(
                        self.songsData[FreeplayState.curSelected][3][1],
                        self.songsData[FreeplayState.curSelected][3][2],
                        self.songsData[FreeplayState.curSelected][3][3])
    self.bg.color[1] = util.coolLerp(self.bg.color[1], colorBG[1], 0.05)
    self.bg.color[2] = util.coolLerp(self.bg.color[2], colorBG[2], 0.05)
    self.bg.color[3] = util.coolLerp(self.bg.color[3], colorBG[3], 0.05)

    FreeplayState.super.update(self, dt)
end

function FreeplayState:changeSelection(huh)
    if huh == nil then huh = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

    FreeplayState.curSelected = FreeplayState.curSelected + huh

    if FreeplayState.curSelected > #self.songsData then
        FreeplayState.curSelected = 1
    elseif FreeplayState.curSelected < 1 then
        FreeplayState.curSelected = #self.songsData
    end

    local bullShit = 0

    for _, item in ipairs(self.grpSongs.members) do
        item.targetY = bullShit - (FreeplayState.curSelected - 1)
        bullShit = bullShit + 1

        item.alpha = 0.6

        if item.targetY == 0 then item.alpha = 1 end
    end
end

return FreeplayState
