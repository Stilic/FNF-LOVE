local Conductor = Object:extend()

function Conductor:new(source, bpm)
    self.source = source
    self.__paused = false
    self.offset = 0
    self.stepsDone = {}

    self:setBPM(bpm)

    self:__updateTime()
end

function Conductor:setBPM(bpm)
    self.bpm = bpm

    self.crochet = (60 / bpm) * 1000
    self.stepCrochet = self.crochet / 4

    self:__updateTime()
    self:__updateBeat()
    self.lastTime = self.time
end

function Conductor:__updateTime()
    self.time = self.source:tell() * 1000 - self.offset

    self.currentStepFloat = self.time / self.stepCrochet
    self.currentStep = math.floor(self.currentStepFloat)
end

function Conductor:__updateBeat()
    self.currentBeatFloat = self.currentStepFloat / 4
    self.currentBeat = math.floor(self.currentBeatFloat)
end

function Conductor:update()
    if self.source:isPlaying() then
        local oldStep = self.currentStep

        self:__updateTime()

        if self.lastTime > self.time then
            self.lastTime = self.time
            self:__step()
        end

        local t = self.lastTime + self.stepCrochet
        if self.time > t then
            self.lastTime = t

            -- borrowed from forever engine -stilic
            local trueDecStep, trueStep = self.currentStepFloat,
                                          self.currentStep
            for i, s in ipairs(self.stepsDone) do
                if s < oldStep then
                    table.remove(self.stepsDone, i)
                end
            end
            for i = oldStep, trueStep do
                if i > 0 and not table.find(self.stepsDone, i) then
                    self.currentStepFloat = i
                    self.currentStep = i
                    self:__updateBeat()
                    self:__step()
                end
            end
            self.currentStepFloat = trueDecStep
            self.currentStep = trueStep
            self:__updateBeat()

            if oldStep ~= trueStep and trueStep > 0 and
                not table.find(self.stepsDone, trueStep) then
                self:__step()
            end
        end
    end
end

function Conductor:__step()
    if self.onStep then self.onStep(self.currentStep) end
    if self.onBeat and self.currentStep % 4 == 0 then
        self.onBeat(self.currentBeat)
    end

    if not table.find(self.stepsDone, self.currentStep) then
        table.insert(self.stepsDone, self.currentStep)
    end
end

function Conductor:play()
    self.source:play()

    self.lastTime = self.time
    if not self.__paused then for _ = 1, 2 do self:__step() end end

    self.__paused = false
end

function Conductor:pause()
    self.__paused = true

    self.source:pause()

    self:__updateTime()
    self:__updateBeat()
end

function Conductor:destroy() self.source:stop() end

return Conductor
