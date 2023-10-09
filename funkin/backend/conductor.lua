local Conductor = Object:extend()

function Conductor:new(sound, bpm)
    self.sound = sound
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

    self.currentStepFloat = self.time / self.stepCrochet
    self.currentStep = math.floor(self.currentStepFloat)

    self.currentBeatFloat = self.currentStepFloat / 4
    self.currentBeat = math.floor(self.currentBeatFloat)
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

function Conductor:__step()
    if self.onStep then self.onStep(self.currentStep) end
    if self.onBeat and self.currentStep % 4 == 0 then
        self.onBeat(self.currentBeat)
    end
end

function Conductor:seek(position, unit)
    local playing = self.sound:isPlaying()
    if playing then self.sound:pause() end
    self.sound:seek(position, unit)
    self:__updateTime()
    if playing then self.sound:play() end
end

return Conductor
