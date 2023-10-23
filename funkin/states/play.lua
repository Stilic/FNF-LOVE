local PauseSubState = require "funkin.substates.pause"

local PlayState = State:extend()

PlayState.controlDirs = {
    note_left = 0,
    note_down = 1,
    note_up = 2,
    note_right = 3
}
PlayState.ratings = {
    {name = "sick", time = 45, score = 350, splash = true, mod = 1},
    {name = "good", time = 90, score = 200, splash = false, mod = 0.7},
    {name = "bad", time = 125, score = 100, splash = false, mod = 0.4},
    {name = "shit", time = 150, score = 50, splash = false, mod = 0.2}
}
PlayState.downscroll = false
PlayState.botPlay = false
PlayState.notePosition = 0

PlayState.SONG = nil

PlayState.storyMode = false
PlayState.pixelStage = false

function PlayState.sortByShit(a, b) return a.time < b.time end

function PlayState:enter()
    self.scripts = ScriptsHandler()
    self.scripts:loadDirectory("scripts/charts")
    self.scripts:call("create")

    self.keysPressed = {}

    if PlayState.SONG == nil then
        PlayState.SONG = paths.getJSON("songs/tutorial/tutorial").song
    end

    self.keysPressed = {}

    if game.sound.music then game.sound.music:stop() end

    local songName = paths.formatToSongPath(PlayState.SONG.song)

    game.sound.music = Sound():load(paths.getInst(songName))
    game.sound.music.onComplete = function()
        game.switchState(FreeplayState())
    end
    PlayState.conductor = Conductor(game.sound.music, PlayState.SONG.bpm)
    PlayState.conductor:mapBPMChanges(PlayState.SONG)
    PlayState.conductor.onBeat = function(b) self:beat(b) end
    PlayState.conductor.onStep = function(s) self:step(s) end
    if PlayState.SONG.needsVoices then
        self.vocals = Sound():load(paths.getVoices(songName))
        game.sound.list:add(self.vocals)
    end

    self.unspawnNotes = {}
    self.allNotes = Group()
    self.notesGroup = Group()
    self.sustainsGroup = Group()

    local curStage = PlayState.SONG.stage
    if PlayState.SONG.stage == nil then
        if songName == 'spookeez' or songName == 'south' or songName ==
            'monster' then
            curStage = 'spooky'
        elseif songName == 'pico' or songName == 'philly-nice' or songName ==
            'blammed' then
            curStage = 'philly'
        elseif songName == "senpai" or songName == "roses" or songName ==
            "thorns" then
            curStage = "school"
        elseif songName == "ugh" or songName == "guns" or songName == "stress" then
            curStage = "tank"
        else
            curStage = "stage"
        end
    end
    PlayState.SONG.stage = curStage

    -- reset ui stage
    PlayState.pixelStage = false

    self.stage = Stage(PlayState.SONG.stage)
    self:add(self.stage)
    table.insert(self.scripts.scripts, self.stage.script)

    local notes = PlayState.SONG.notes
    for _, s in ipairs(notes) do
        if s and s.sectionNotes then
            for _, n in ipairs(s.sectionNotes) do
                local daStrumTime = tonumber(n[1])
                local daNoteData = tonumber(n[2])
                if daStrumTime ~= nil and daNoteData ~= nil then
                    daNoteData = daNoteData % 4
                    local gottaHitNote = s.mustHitSection
                    if n[2] > 3 then
                        gottaHitNote = not gottaHitNote
                    end

                    local oldNote
                    if #self.unspawnNotes > 0 then
                        oldNote = self.unspawnNotes[#self.unspawnNotes]
                    end

                    local note = Note(daStrumTime, daNoteData, oldNote)
                    note.mustPress = gottaHitNote
                    note.altNote = n[4]
                    note:setScrollFactor()
                    table.insert(self.unspawnNotes, note)

                    if n[3] ~= nil then
                        local susLength = tonumber(n[3])
                        if susLength ~= nil and susLength > 0 then
                            susLength = math.round(n[3] /
                                                       PlayState.conductor
                                                           .stepCrochet)

                            for susNote = 0, math.max(math.floor(susLength) - 1,
                                                      1) do
                                oldNote = self.unspawnNotes[#self.unspawnNotes]

                                local sustain = Note(daStrumTime +
                                                         PlayState.conductor
                                                             .stepCrochet *
                                                         (susNote + 1),
                                                     daNoteData, oldNote, true,
                                                     note)
                                sustain.mustPress = gottaHitNote
                                sustain:setScrollFactor()
                                table.insert(self.unspawnNotes, sustain)
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(self.unspawnNotes, PlayState.sortByShit)

    PlayState.notePosition = -PlayState.conductor.crochet * 5

    self.score = 0
    self.combo = 0
    self.misses = 0
    self.accuracy = 0
    self.health = 1

    self.totalPlayed = 0
    self.totalHit = 0.0

    game.camera.target = {x = 0, y = 0}

    self.camHUD = Camera()
    self.camOther = Camera()
    game.cameras.add(self.camHUD, false)
    game.cameras.add(self.camOther, false)

    self.receptors = Group()
    self.playerReceptors = Group()
    self.enemyReceptors = Group()

    local rx, ry = game.width / 2, 50
    if PlayState.downscroll then ry = game.height - 100 - ry end
    for i = 0, 1 do
        for j = 0, 3 do
            local rep = Receptor(rx + (game.width / 4) * (i == 1 and 1 or -1),
                                 ry, j, i)
            rep:groupInit()
            self.receptors:add(rep)
            if i == 1 then
                self.playerReceptors:add(rep)
            else
                self.enemyReceptors:add(rep)
            end
        end
    end

    self.splashes = Group()

    local splash = NoteSplash()
    splash.alpha = 0
    self.splashes:add(splash)

    self.judgeSprites = Group()

    self.camFollow = {x = 0, y = 0}
    self.camZooming = false

    game.camera.zoom = self.stage.camZoom

    local gfVersion = PlayState.SONG.gfVersion
    if gfVersion == nil then
        switch(curStage, {
            ["school"] = function() gfVersion = "gf-pixel" end,
            ["tank"] = function() gfVersion = "gf-tankmen" end,
            default = function() gfVersion = "gf" end
        })
        PlayState.SONG.gfVersion = gfVersion
    end

    self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
                        self.SONG.gfVersion, false)
    self.gf:setScrollFactor(0.95, 0.95)

    self.boyfriend = Character(self.stage.boyfriendPos.x,
                               self.stage.boyfriendPos.y, self.SONG.player1,
                               true)
    self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y,
                         self.SONG.player2, false)

    self:add(self.gf)
    self:add(self.boyfriend)
    self:add(self.dad)

    self:add(self.stage.foreground)
    self:add(self.judgeSprites)

    self.healthBarBG = Sprite()
    self.healthBarBG:loadTexture(paths.getImage("skins/normal/healthBar"))
    self.healthBarBG:updateHitbox()
    self.healthBarBG:screenCenter("x")
    self.healthBarBG.y = (PlayState.downscroll and game.height * 0.1 or
                             game.height * 0.9)
    self.healthBarBG:setScrollFactor()

    self.healthBar = Bar(self.healthBarBG.x + 4, self.healthBarBG.y + 4,
                         math.floor(self.healthBarBG.width - 8),
                         math.floor(self.healthBarBG.height - 8), 2, nil, true)
    self.healthBar:setValue(self.health)

    self.iconP1 = HealthIcon(self.boyfriend.icon, true)
    self.iconP1.y = self.healthBar.y - 75

    self.iconP2 = HealthIcon(self.dad.icon, false)
    self.iconP2.y = self.healthBar.y - 75

    local textOffset = 30
    if PlayState.downscroll then textOffset = -textOffset end

    local font = paths.getFont("vcr.ttf", 16)
    self.scoreTxt = Text(0, self.healthBarBG.y + textOffset, "", font,
                         {1, 1, 1}, "center")
    self.scoreTxt.outWidth = 1

    self.timeTxt = Text(0, self.healthBar.y - textOffset, "", font, {1, 1, 1},
                        "center")
    self.timeTxt.outWidth = 1

    self.timeArcBG = Graphic(self.timeTxt.x - 20, self.timeTxt.y + 6, 100, 100,
                             {0, 0, 0}, "arc", "line")
    self.timeArcBG.outWidth = 7
    self.timeArcBG.config = {
        radius = 8,
        arctype = "closed",
        angle1 = 0,
        angle2 = 360,
        segments = 40
    }
    self.timeArcBG:updateDimensions()

    self.timeArc = Graphic(self.timeArcBG.x, self.timeArcBG.y, 100, 100,
                           {1, 1, 1}, "arc", "line")
    self.timeArc.outWidth = 2
    self.timeArc.config = {
        radius = 8,
        arctype = "open",
        angle1 = -90,
        angle2 = 0,
        segments = 40
    }
    self.timeArc:updateDimensions()

    self:add(self.receptors)
    self:add(self.sustainsGroup)
    self:add(self.notesGroup)
    self:add(self.splashes)

    self:add(self.healthBarBG)
    self:add(self.healthBar)
    self:add(self.iconP1)
    self:add(self.iconP2)
    self:add(self.scoreTxt)
    self:add(self.timeArcBG)
    self:add(self.timeArc)
    self:add(self.timeTxt)

    self:recalculateRating()

    for _, o in ipairs({
        self.receptors, self.splashes, self.notesGroup, self.sustainsGroup,
        self.healthBarBG, self.healthBar, self.iconP1, self.iconP2,
        self.scoreTxt, self.timeArcBG, self.timeArc, self.timeTxt
    }) do o.cameras = {self.camHUD} end

    self.bindedKeyPress = function(...) self:onKeyPress(...) end
    controls:bindPress(self.bindedKeyPress)

    self.bindedKeyRelease = function(...) self:onKeyRelease(...) end
    controls:bindRelease(self.bindedKeyRelease)

    self.startingSong = true

    self.countdownTimer = Timer.new()

    local basePath = "skins/" .. (PlayState.pixelStage and "pixel" or "normal")
    local countdownData = {
        nil, -- state opened
        {sound = basePath .. "/intro3", image = nil},
        {sound = basePath .. "/intro2", image = basePath .. "/ready"},
        {sound = basePath .. "/intro1", image = basePath .. "/set"},
        {sound = basePath .. "/introGo", image = basePath .. "/go"}
    }

    local crochet = PlayState.conductor.crochet / 1000
    for swagCounter = 1, 6 do
        self.countdownTimer:after(crochet * (swagCounter - 1), function()
            local data = countdownData[swagCounter]
            if data then
                if data.sound then
                    game.sound.play(paths.getSound(data.sound))
                end
                if data.image then
                    local countdownSprite = Sprite()
                    countdownSprite:loadTexture(paths.getImage(data.image))
                    countdownSprite.cameras = {self.camHUD}
                    if PlayState.pixelStage then
                        countdownSprite.scale = {x = 6, y = 6}
                    end
                    countdownSprite:updateHitbox()
                    countdownSprite.antialiasing = not PlayState.pixelStage
                    countdownSprite:screenCenter()

                    Timer.tween(crochet, countdownSprite, {alpha = 0},
                                "in-out-cubic", function()
                        self:remove(countdownSprite)
                        countdownSprite:destroy()
                    end)
                    self:add(countdownSprite)
                end
            end

            self.boyfriend:beat(swagCounter)
            self.gf:beat(swagCounter)
            self.dad:beat(swagCounter)
        end)
    end

    self.scripts:call("postCreate")
end

function PlayState:update(dt)
    self.scripts:call("update", dt)

    self.countdownTimer:update(dt)

    PlayState.notePosition = PlayState.notePosition + 1000 * dt
    if self.startingSong and PlayState.notePosition >= 0 then
        self.startingSong = false
        PlayState.conductor.sound:play()
        if self.vocals then self.vocals:play() end
        PlayState.notePosition = PlayState.conductor.time
        self.scripts:call("songStart")
    end

    PlayState.super.update(self, dt)

    PlayState.conductor:update()

    game.camera.target.x, game.camera.target.y =
        util.coolLerp(game.camera.target.x, self.camFollow.x,
                      0.04 * self.stage.camSpeed),
        util.coolLerp(game.camera.target.y, self.camFollow.y,
                      0.04 * self.stage.camSpeed)

    local mult = util.coolLerp(self.iconP1.scale.x, 1, 0.25)
    self.iconP1.scale = {x = mult, y = mult}
    self.iconP2.scale = {x = mult, y = mult}

    self.iconP1:updateHitbox()
    self.iconP2:updateHitbox()

    local iconOffset = 26
    self.iconP1.x = self.healthBar.x + (self.healthBar.width *
                        (math.remapToRange(self.healthBar.percent, 0, 100, 100,
                                           0) * 0.01) - iconOffset)

    self.iconP2.x = self.healthBar.x + (self.healthBar.width *
                        (math.remapToRange(self.healthBar.percent, 0, 100, 100,
                                           0) * 0.01)) -
                        (self.iconP2.width - iconOffset)

    self.iconP1:swap((self.health < 0.2 and 2 or 1))
    self.iconP2:swap((self.health > 1.8 and 2 or 1))

    -- time arc / text
    local songTime = PlayState.conductor.time / 1000

    local mode = "left" -- for now until ClientPrefs is a thing - Vi
    if mode == "left" then
        songTime = PlayState.conductor.sound:getDuration() - songTime
    end

    self.timeTxt:setContent(util.getFormattedTime(songTime))

    self.timeTxt:screenCenter("x")
    self.timeTxt.x = self.timeTxt.x + (self.timeArcBG.width + 5)

    self.timeArcBG:screenCenter("x")
    self.timeArcBG.x = self.timeTxt.x - self.timeArcBG.width - 5
    self.timeArc.x = self.timeArcBG.x

    local timeAngle = ((PlayState.conductor.time / 1000) /
                          (PlayState.conductor.sound:getDuration() / 1000)) *
                          0.36
    self.timeArc.config.angle2 = -90 + math.ceil(timeAngle)

    local section = self:getCurrentSection()
    if section ~= nil then
        if section.gfSection then
            local x, y = self.gf:getMidpoint()
            self.camFollow.x = x -
                                   (self.gf.cameraPosition.x -
                                       self.stage.gfCam.x)
            self.camFollow.y = y -
                                   (self.gf.cameraPosition.y -
                                       self.stage.gfCam.y)
        else
            if section.mustHitSection then
                local x, y = self.boyfriend:getMidpoint()
                self.camFollow.x = x - 100 -
                                       (self.boyfriend.cameraPosition.x -
                                           self.stage.boyfriendCam.x)
                self.camFollow.y = y - 100 +
                                       (self.boyfriend.cameraPosition.y +
                                           self.stage.boyfriendCam.y)
            else
                local x, y = self.dad:getMidpoint()
                self.camFollow.x = x + 150 +
                                       (self.dad.cameraPosition.x +
                                           self.stage.dadCam.x)
                self.camFollow.y = y - 100 +
                                       (self.dad.cameraPosition.y +
                                           self.stage.dadCam.y)
            end
        end
    end

    if self.camZooming then
        game.camera.zoom = util.coolLerp(game.camera.zoom, self.stage.camZoom,
                                          0.0475)
        self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 0.0475)
    end

    if controls:pressed("pause") then
        PlayState.conductor.sound:pause()
        if self.vocals then self.vocals:pause() end

        self.paused = true

        local pause = PauseSubState()
        pause.cameras = {self.camOther}
        self:openSubState(pause)
    end
    if controls:pressed("debug_1") then
        PlayState.conductor.sound:pause()
        if self.vocals then self.vocals:pause() end
        game.switchState(ChartingState())
    end
    if controls:pressed("debug_2") then
        PlayState.conductor.sound:pause()
        if self.vocals then self.vocals:pause() end
        CharacterEditor.onPlayState = true
        game.switchState(CharacterEditor())
    end

    if self.unspawnNotes[1] then
        local time = 2000
        if PlayState.SONG.speed < 1 then
            time = time / PlayState.SONG.speed
        end
        while #self.unspawnNotes > 0 and self.unspawnNotes[1].time -
            PlayState.notePosition < time do
            local n = table.remove(self.unspawnNotes, 1)
            local grp = n.isSustain and self.sustainsGroup or self.notesGroup
            self.allNotes:add(n)
            grp:add(n)
        end
    end

    local ogCrochet = (60 / PlayState.SONG.bpm) * 1000
    local ogStepCrochet = ogCrochet / 4
    for i, n in ipairs(self.allNotes.members) do
        if not self.startingSong and not n.tooLate and ((not n.mustPress or PlayState.botPlay) and
            ((n.isSustain and n.canBeHit) or n.time <= PlayState.notePosition) or
            (n.isSustain and self.keysPressed[n.data] and n.parentNote and
                n.parentNote.wasGoodHit and n.canBeHit)) then
            self:goodNoteHit(n)
        end

        local time = n.time
        if n.isSustain and PlayState.SONG.speed ~= 1 then
            time = time - ogStepCrochet + ogStepCrochet / PlayState.SONG.speed
        end

        local r =
            (n.mustPress and self.playerReceptors or self.enemyReceptors).members[n.data +
                1]
        local sy = r.y + n.scrollOffset.y

        n.x = r.x + n.scrollOffset.x
        n.y = sy - (PlayState.notePosition - time) *
                  (0.45 * PlayState.SONG.speed) *
                  (PlayState.downscroll and -1 or 1)

        if n.isSustain then
            n.flipY = PlayState.downscroll
            if n.flipY then
                if n.flipY then
                    if n.isSustainEnd then
                        n.y = n.y + (43.5 * 0.7) *
                                  (PlayState.conductor.stepCrochet / 100 * 1.5 *
                                      PlayState.SONG.speed) - n.height
                    end
                    n.y = n.y + Note.swagWidth / 2 - 60.5 *
                              (PlayState.SONG.speed - 1) + 27.5 *
                              (PlayState.SONG.bpm / 100 - 1) *
                              (PlayState.SONG.speed - 1)
                else
                    n.y = n.y + Note.swagWidth / 10
                end
            else
                n.y = n.y + Note.swagWidth / 12
            end

            if (n.wasGoodHit or n.prevNote.wasGoodHit) and
                (not n.mustPress or PlayState.botPlay or
                    self.keysPressed[n.data] or n.isSustainEnd) then
                local center = sy + Note.swagWidth / 2
                local vert = center - n.y
                if PlayState.downscroll then
                    if n.y - n.offset.y + n:getFrameHeight() * n.scale.y >=
                        center then
                        if not n.clipRect then
                            n.clipRect = {}
                        end
                        n.clipRect.x, n.clipRect.y = 0, 0
                        n.clipRect.width, n.clipRect.height =
                            n:getFrameWidth() * n.scale.x, vert
                    end
                elseif n.y + n.offset.y <= center then
                    if not n.clipRect then n.clipRect = {} end
                    n.clipRect.x, n.clipRect.y = 0, vert
                    n.clipRect.width, n.clipRect.height =
                        n:getFrameWidth() * n.scale.x,
                        n:getFrameHeight() * n.scale.y - vert
                end
            end
        end

        if PlayState.notePosition > 350 / PlayState.SONG.speed + n.time then
            if n.mustPress and not n.wasGoodHit and
                (not n.isSustain or not n.parentNote.tooLate) then
                if self.vocals then self.vocals:setVolume(0) end
                self.combo = 0
                self.score = self.score - 100
                self.misses = self.misses + 1

                self.totalPlayed = self.totalPlayed + 1
                self:recalculateRating()

                local np = n.isSustain and n.parentNote or n
                np.tooLate = true
                for _, no in ipairs(np.children) do
                    no.tooLate = true
                end

                if self.health < 0 then self.health = 0 end

                self.health = self.health - 0.0475
                self.healthBar:setValue(self.health)

                self.boyfriend:sing(n.data, true)
            end

            self:removeNote(n)
        end
    end

    self.scripts:call("postUpdate", dt)
end

function PlayState:draw()
    self.scripts:call("draw")
    PlayState.super.draw(self)
    self.scripts:call("postDraw")
end

function PlayState:closeSubState()
    PlayState.super.closeSubState(self)
    if not self.startingSong then
        if self.vocals and not self.startingSong then
            self.vocals:seek(PlayState.conductor.sound:tell())
        end
        PlayState.conductor.sound:play()
        if self.vocals then self.vocals:play() end
    end
end

-- CAN RETURN NIL!!
function PlayState:getCurrentSection()
    return
        PlayState.SONG.notes[math.floor(PlayState.conductor.currentStep / 16) +
            1]
end

function PlayState:getKeyFromEvent(controls)
    for _, control in next, controls do
        if PlayState.controlDirs[control] then
            return PlayState.controlDirs[control]
        end
    end
    return -1
end

function PlayState:onKeyPress(key, type)
    if not PlayState.botPlay and (not self.subState or self.persistentUpdate) then
        local controls = controls:getControlsFromSource(type .. ":" .. key)
        if not controls then return end
        key = self:getKeyFromEvent(controls)
        if key >= 0 then
            self.keysPressed[key] = true

            if not self.startingSong then
                local noteList = {}

                for _, n in ipairs(self.notesGroup.members) do
                    if n.mustPress and not n.isSustain and not n.tooLate and
                        not n.wasGoodHit then
                        if not n.canBeHit and
                            n:checkDiff(PlayState.conductor.time) then
                            n:update(0)
                        end
                        if n.canBeHit and n.data == key then
                            table.insert(noteList, n)
                        end
                    end
                end

                if #noteList > 0 then
                    table.sort(noteList, PlayState.sortByShit)
                    local coolNote = table.remove(noteList, 1)

                    for _, n in next, noteList do
                        if n.time - coolNote.time < 2 then
                            self:removeNote(n)
                        end
                    end

                    self:goodNoteHit(coolNote)
                end
            end

            local r = self.playerReceptors.members[key + 1]
            if r and r.curAnim.name ~= "confirm" then
                r:play("pressed")
            end
        end
    end
end

function PlayState:onKeyRelease(key, type)
    if not PlayState.botPlay and (not self.subState or self.persistentUpdate) then
        local controls = controls:getControlsFromSource(type .. ":" .. key)
        if not controls then return end
        key = self:getKeyFromEvent(controls)
        if key >= 0 then
            self.keysPressed[key] = false

            local r = self.playerReceptors.members[key + 1]
            if r then
                r:play("static")
                r.confirmTimer = 0
            end
        end
    end
end

function PlayState:goodNoteHit(n)
    if not n.wasGoodHit then
        n.wasGoodHit = true
        self.scripts:call("goodNoteHit", n)

        if self.vocals then self.vocals:setVolume(1) end

        local char = (n.mustPress and self.boyfriend or self.dad)
        char:sing(n.data, false)

        if not n.mustPress then self.camZooming = true end

        local time = 0
        if not n.mustPress or PlayState.botPlay then
            time = 0.15
            if n.isSustain and not n.isSustainEnd then
                time = time * 2
            end
        end
        local receptor = (n.mustPress and self.playerReceptors or
                             self.enemyReceptors).members[n.data + 1]
        receptor:confirm(time)

        if not n.isSustain then
            if n.mustPress then
                local diff, rating =
                    math.abs(n.time - PlayState.conductor.time),
                    PlayState.ratings[#PlayState.ratings - 1]
                for _, r in next, PlayState.ratings do
                    if diff <= r.time then
                        rating = r
                        break
                    end
                end

                self.combo = self.combo + 1
                self.score = self.score + rating.score

                if rating.splash then
                    local splash = self.splashes:recycle(NoteSplash)
                    splash.x, splash.y = receptor.x, receptor.y
                    splash:setup(n.data)
                end
                self:popUpScore(rating)

                self.totalHit = self.totalHit + rating.mod
                self.totalPlayed = self.totalPlayed + 1
                self:recalculateRating()

                if self.health > 2 then self.health = 2 end

                self.health = self.health + 0.023
                self.healthBar:setValue(self.health)
            end

            self:removeNote(n)

            self.scripts:call("postGoodNoteHit", n)
        end
    end
end

function PlayState:removeNote(n)
    n:destroy()
    self.allNotes:remove(n)
    if n.isSustain then
        self.sustainsGroup:remove(n)
    else
        self.notesGroup:remove(n)
    end
end

function PlayState:step(s)
    -- now it works -fellynn
    local time = PlayState.conductor.sound:tell()
    if self.vocals and math.abs(self.vocals:tell() * 1000 - time * 1000) > 20 then
        self.vocals:seek(time)
    end
    if math.abs(time * 1000 - PlayState.notePosition) > 20 then
        PlayState.notePosition = time * 1000
    end

    self.scripts:call("step", s)

    self.boyfriend:step(s)
    self.gf:step(s)
    self.dad:step(s)

    self.scripts:call("postStep", s)
end

function PlayState:beat(b)
    self.scripts:call("beat", b)

    local section = self:getCurrentSection()
    if b % ((section and section.sectionBeats) and section.sectionBeats or 4) ==
        0 then
        if section and section.changeBPM then
            print("bpm change! OLD BPM: " .. PlayState.conductor.bpm ..
                      ", NEW BPM: " .. section.bpm)
            PlayState.conductor:setBPM(section.bpm)
        end

        if self.camZooming and game.camera.zoom < 1.35 then
            game.camera.zoom = game.camera.zoom + 0.015
            self.camHUD.zoom = self.camHUD.zoom + 0.03
        end
    end

    local scaleNum = 1.2
    self.iconP1.scale = {x = scaleNum, y = scaleNum}
    self.iconP2.scale = {x = scaleNum, y = scaleNum}

    self.boyfriend:beat(b)
    self.gf:beat(b)
    self.dad:beat(b)

    self.scripts:call("postBeat", b)
end

function PlayState:popUpScore(rating)
    local accel = PlayState.conductor.crochet * 0.001

    local judgeSpr = self.judgeSprites:recycle()

    local antialias = not PlayState.pixelStage
    local uiStage = PlayState.pixelStage and "pixel" or "normal"

    judgeSpr:loadTexture(paths.getImage("skins/" .. uiStage .. "/" ..
                                            rating.name))
    judgeSpr.alpha = 1
    judgeSpr:setGraphicSize(math.floor(judgeSpr.width *
                                           (PlayState.pixelStage and 4.7 or 0.7)))
    judgeSpr:updateHitbox()
    judgeSpr:screenCenter()
    judgeSpr.moves = true
    -- use fixed values to display at the same position on a different resolution
    judgeSpr.x = (1280 - judgeSpr.width) * 0.5 + 190
    judgeSpr.y = (720 - judgeSpr.height) * 0.5 - 60
    judgeSpr.velocity.x = 0
    judgeSpr.velocity.y = 0
    judgeSpr.alpha = 1
    judgeSpr.antialiasing = antialias

    judgeSpr.acceleration.y = 550
    judgeSpr.velocity.y = judgeSpr.velocity.y - math.random(140, 175)
    judgeSpr.velocity.x = judgeSpr.velocity.x - math.random(0, 10)

    Timer.after(accel, function()
        Timer.tween(0.2, judgeSpr, {alpha = 0}, "linear", function()
            Timer.cancelTweensOf(judgeSpr)
            judgeSpr:kill()
        end)
    end)

    if self.combo >= 10 then
        local lastSpr
        local coolX, comboStr = 1280 * 0.55, string.format("%03d", self.combo)
        for i = 1, #comboStr do
            local digit = tonumber(comboStr:sub(i, i)) or 0
            local numScore = self.judgeSprites:recycle()
            numScore:loadTexture(paths.getImage(
                                     "skins/" .. uiStage .. "/num" .. digit))
            numScore:setGraphicSize(math.floor(numScore.width *
                                                   (PlayState.pixelStage and 4.5 or
                                                       0.5)))
            numScore:updateHitbox()
            numScore.moves = true
            numScore.x = (lastSpr and lastSpr.x or coolX - 90) + numScore.width
            numScore.y = judgeSpr.y + 115
            numScore.velocity.y = 0
            numScore.velocity.x = 0
            numScore.alpha = 1
            numScore.antialiasing = antialias

            numScore.acceleration.y = math.random(200, 300)
            numScore.velocity.y = numScore.velocity.y - math.random(140, 160)
            numScore.velocity.x = math.random(-5.0, 5.0)

            Timer.after(accel * 2, function()
                Timer.tween(0.2, numScore, {alpha = 0}, "linear", function()
                    Timer.cancelTweensOf(numScore)
                    numScore:kill()
                end)
            end)

            lastSpr = numScore
        end
    end
end

function PlayState:recalculateRating()
    if self.totalPlayed > 0 then
        self.accuracy = math.min(1,
                                 math.max(0, self.totalHit / self.totalPlayed))
    end

    self.scoreTxt:setContent("Score: " .. self.score .. " // Misses: " ..
                                 self.misses .. " // " ..
                                 util.floorDecimal(self.accuracy * 100, 2) ..
                                 "%")
    self.scoreTxt:screenCenter("x")
end

function PlayState:leave()
    self.scripts:call("leave")

    PlayState.conductor = nil
    game.sound.music:destroy()
    game.sound.music = nil

    controls:unbindPress(self.bindedKeyPress)
    controls:unbindRelease(self.bindedKeyRelease)

    self.scripts:call("postLeave")
end

return PlayState
