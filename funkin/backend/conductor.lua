local Conductor = Object:extend()

function Conductor:new(sound, bpm)
    self.sound = sound
    self.__bpmChanges = {}
    self:setBPM(bpm)
end

function Conductor:setBPM(bpm)
    self.bpm = bpm

    self.crochet = (60 / bpm) * 1000
    self.stepCrochet = self.crochet / 4

    self:__updateTime()
end

function Conductor:__updateTime()
    self.time = self.sound:tell() * 1000

    local stepTime, songTime = 0, 0
    for _, c in ipairs(self.__bpmChanges) do
        if self.time >= c[2] then stepTime, songTime = c[1], c[2] end
    end
    self.currentStepFloat = stepTime + (self.time - songTime) / self.stepCrochet
    self.currentStep = math.floor(self.currentStepFloat)

    self.currentBeatFloat = self.currentStepFloat / 4
    self.currentBeat = math.floor(self.currentBeatFloat)
end

function Conductor:__step()
    if self.onStep then self.onStep(self.currentStep) end
    if self.onBeat and self.currentStep % 4 == 0 then
        self.onBeat(self.currentBeat)
    end
end

function Conductor:update()
    if self.sound:isPlaying() then
        local step = self.currentStep
        self:__updateTime()
        if step ~= self.currentStep and self.currentStep >= 0 then
            self:__step()
        end
    end
end

function Conductor:seek(position, unit)
    local playing = self.sound:isPlaying()
    if playing then self.sound:pause() end
    self.sound:seek(position, unit)
    self:__updateTime()
    if playing then self.sound:play() end
end

function Conductor:mapBPMChanges(song)
    self.__bpmChanges = {}

    local bpm, totalSteps, totalPos, toAdd = song.bpm, 0, 0,
                                             ((60 / song.bpm) * 1000 / 4)
    for i, s in ipairs(song.notes) do
        if s.changeBPM and s.bpm ~= bpm then
            bpm = s.bpm
            toAdd = ((60 / bpm) * 1000 / 4)
            table.insert(self.__bpmChanges, {totalSteps, totalPos, bpm})
        end

        local section = song.notes[i]
        local deltaSteps = math.round((section.sectionBeats ~= nil and
                                          section.sectionBeats or 4) * 4)
        totalSteps = totalSteps + deltaSteps
        totalPos = totalPos + toAdd * deltaSteps
    end
end

return Conductor
