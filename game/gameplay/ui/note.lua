local Note = Sprite:extend()

Note.swagWidth = 160 * 0.7
Note.colors = {"purple", "blue", "green", "red"}
Note.directions = {"left", "down", "up", "right"}
Note.pixelAnim = {{{4}, {0}}, {{5}, {1}}, {{6}, {2}}, {{7}, {3}}}

function Note:new(time, data, prevNote, sustain, parentNote)
    Note.super.new(self, 0, -2000)

    self.time = time
    self.data = data
    self.prevNote = prevNote
    if sustain == nil then sustain = false end
    self.isSustain, self.isSustainEnd, self.isSustainEnd = sustain, false, false
    self.parentNote, children = parentNote, false
    self.mustPress = false
    self.canBeHit, self.wasGoodHit, self.tooLate = false, false, false
    self.earlyHitMult, self.lateHitMult = 1, 1
    self.altNote = false

    self.scrollOffset = {x = 0, y = 0}

    local color = Note.colors[data + 1]
    if PlayState.pixelStage then
        if sustain then
            self:load(paths.getImage('skins/pixel/NOTE_assetsENDS'))
            self.width = self.width / 4
            self.height = self.height / 2
            self:load(paths.getImage('skins/pixel/NOTE_assetsENDS'), true,
                      math.floor(self.width), math.floor(self.height))

            self:addAnim(color .. 'holdend', Note.pixelAnim[data + 1][1])
            self:addAnim(color .. 'hold', Note.pixelAnim[data + 1][2])
        else
            self:load(paths.getImage('skins/pixel/NOTE_assets'))
            self.width = self.width / 4
            self.height = self.height / 5
            self:load(paths.getImage('skins/pixel/NOTE_assets'), true,
                      math.floor(self.width), math.floor(self.height))

            self:addAnim(color .. 'Scroll', Note.pixelAnim[data + 1][1])
        end

        self:setGraphicSize(math.floor(self.width * 6))
        self.antialiasing = false
    else
        self:setFrames(paths.getSparrowAtlas("skins/normal/NOTE_assets"))

        if sustain then
            if data == 0 then
                self:addAnimByPrefix(color .. "holdend", "pruple end hold")
            else
                self:addAnimByPrefix(color .. "holdend", color .. " hold end")
            end
            self:addAnimByPrefix(color .. "hold", color .. " hold piece")
        else
            self:addAnimByPrefix(color .. "Scroll", color .. "0")
        end

        self:setGraphicSize(math.floor(self.width * 0.7))
    end
    self:updateHitbox()

    self:play(color .. "Scroll")

    if sustain and prevNote then
        table.insert(parentNote.children, self)

        self.alpha = 0.6
        self.earlyHitMult = 0.5
        self.scrollOffset.x = self.scrollOffset.x + self.width / 2

        self:play(color .. "holdend")
        self.isSustainEnd = true

        self:updateHitbox()

        self.scrollOffset.x = self.scrollOffset.x - self.width / 2

        if PlayState.pixelStage then
            self.scrollOffset.x = self.scrollOffset.x + 30
        end

        if prevNote.isSustain then
            prevNote:play(Note.colors[prevNote.data + 1] .. "hold")
            prevNote.isSustainEnd = false

            prevNote.scale.y = (prevNote.width / prevNote:getFrameWidth()) *
                                   ((PlayState.inst.stepCrochet / 100) *
                                       (1.05 / 0.7)) * PlayState.song.speed

            if PlayState.pixelStage then
                prevNote.scale.y = prevNote.scale.y * 5
                prevNote.scale.y = prevNote.scale.y * (6 / self.height)
            end
            prevNote:updateHitbox()
        end
    else
        self.children = {}
    end
end

local safeZoneOffset = (10 / 60) * 1000

function Note:checkDiff()
    return self.time > PlayState.songPosition - safeZoneOffset *
               self.lateHitMult and self.time < PlayState.songPosition +
               safeZoneOffset * self.earlyHitMult
end

function Note:update(dt)
    self.canBeHit = self:checkDiff()

    if self.mustPress then
        if not self.wasGoodHit and self.time < PlayState.songPosition -
            safeZoneOffset then self.tooLate = true end
    end

    if self.tooLate and self.alpha > 0.3 then self.alpha = 0.3 end

    Note.super.update(self, dt)
end

return Note
