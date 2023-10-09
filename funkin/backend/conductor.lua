local Conductor = Object:extend()

function Conductor:new(sound, bpm)
    self.sound = sound
    self.__stepsDone = {}
    self.__lastTime = 0

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
        local oldCurStep = self.currentStep

        self:__updateTime()

        -- borrowed from forever engine -stilic
        local trueDecStep, trueStep = self.currentStepFloat, self.currentStep

        for i, s in ipairs(self.__stepsDone) do
            if s < oldCurStep then table.remove(self.__stepsDone, i) end
        end

        for i = oldCurStep, trueStep do
            if i > 0 and not table.find(self.__stepsDone, i) then
                self.currentStepFloat = i
                self.currentStep = i

                self:__step()

                table.insert(self.__stepsDone, i)
            end
        end

        -- music looped
        if self.currentStep < oldCurStep then self:__step() end

        self.currentStepFloat = trueDecStep
        self.currentStep = trueStep

        if self.onStep and oldCurStep ~= trueStep and trueStep > 0 and
            not table.find(self.__stepsDone, trueStep) then
            self:__step()

            if not table.find(self.stepsDone, trueStep) then
                table.insert(self.stepsDone, trueStep)
            end
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
