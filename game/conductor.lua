local Conductor = Object:extend()

Conductor.instances = {}

function Conductor:new(source, bpm)
    self.__source = source
    self.__paused = false
    self.__stepsDone = {}
    self.__lastTime = 0

    self:setBPM(bpm)

    table.insert(Conductor.instances, self)
end

function Conductor:setBPM(bpm)
    self.bpm = bpm

    self.crochet = (60 / bpm) * 1000
    self.stepCrochet = self.crochet / 4

    self:__updateTime()
end

function Conductor:__updateTime()
    self.time = self.__source:tell() * 1000

    self.currentStepFloat = self.time / self.stepCrochet
    self.currentStep = math.floor(self.currentStepFloat)

    self.currentBeatFloat = self.currentStepFloat / 4
    self.currentBeat = math.floor(self.currentBeatFloat)
end

function Conductor:update()
    if self.__source:isPlaying() then
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

function Conductor:play()
    self.__source:play()
    self.__paused = false

    self:__updateTime()
end

function Conductor:pause()
    self.__source:pause()
    self.__paused = true
end

function Conductor:isPaused() return self.__paused end

function Conductor:isFinished()
    return not self.__source:isPlaying() and not self:isPaused()
end

function Conductor:setLooping(state) self.__source:setLooping(state) end

function Conductor:isLooping() return self.__source:isLooping() end

function Conductor:seek(position, unit)
    local playing = self.__source:isPlaying()
    if playing then self.__source:pause() end
    self.__source:seek(position, unit)
    self:__updateTime()
    if playing then self.__source:play() end
end

function Conductor:destroy()
    table.remove(Conductor.instances, table.find(Conductor.instances, self))
    self.__source:stop()
    self.__source = nil
end

return Conductor
