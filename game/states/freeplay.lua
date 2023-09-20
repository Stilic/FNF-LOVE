local FreeplayState = State:extend()

FreeplayState.curSelected = 1

function FreeplayState:enter()
    self.songs = {
        'Test', 'Tutorial', 'Bopeebo', 'Fresh', 'Dad Battle', 'Senpai', 'Roses',
        'Thorns', 'Ugh', 'Guns', 'Stress', 'Triple B Trouble', 'Yaro Phantasma'
    }

    self.bg = Sprite()
    self.bg:load(paths.getImage('menus/mainmenu/menuBGBlue'))
    self:add(self.bg)
    self.bg:screenCenter()

    self.grpSongs = Group()
    self:add(self.grpSongs)

    for i = 0, #self.songs - 1 do
        local songText = Alphabet(0, (70 * i) + 30, self.songs[i + 1], true,
                                  false)
        songText.isMenuItem = true
        songText.targetY = i
        self.grpSongs:add(songText)

        if songText:getWidth() > 980 then
            local textScale = 980 / songText:getWidth()
            songText.scale.x = textScale
            for _, letter in pairs(songText.lettersArray) do
                letter.x = letter.x * textScale
                letter.offset.x = letter.offset.x * textScale
            end
        end
    end

    self:changeSelection()
end

function FreeplayState:update(dt)
    if controls:pressed('ui_up') then self:changeSelection(-1) end
    if controls:pressed('ui_down') then self:changeSelection(1) end

    if controls:pressed("back") then
        paths.playSound('cancelMenu')
        switchState(MainMenuState())
    end
    if controls:pressed('accept') then
        local daSong = paths.formatToSongPath(self.songs[FreeplayState.curSelected])
        PlayState.SONG = paths.getJSON("songs/"..daSong.."/"..daSong).song
        switchState(PlayState())
    end

    FreeplayState.super.update(self, dt)
end

function FreeplayState:changeSelection(huh)
    if huh == nil then huh = 0 end
    paths.playSound('scrollMenu')

    FreeplayState.curSelected = FreeplayState.curSelected + huh

    if FreeplayState.curSelected > #self.songs then
        FreeplayState.curSelected = 1
    elseif FreeplayState.curSelected < 1 then
        FreeplayState.curSelected = #self.songs
    end

    local bullShit = 0

    for _, item in pairs(self.grpSongs.members) do
        item.targetY = bullShit - (FreeplayState.curSelected - 1)
        bullShit = bullShit + 1

        item.alpha = 0.6

        if item.targetY == 0 then item.alpha = 1 end
    end
end

return FreeplayState