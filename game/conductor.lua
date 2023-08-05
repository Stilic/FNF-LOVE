local Conductor = Object:extend()

function Conductor:new(source, bpm)
    self.source = source
    self.offset = 0

    self:setBPM(bpm)

    self:updateTime()
    self:updateStep()
end

function Conductor:setBPM(bpm)
    self.bpm = bpm

    self.crochet = (60 / bpm)
    self.stepCrochet = self.crochet / 4

    self:updateTime()
    self:updateStep()
    self.lastTime = self.time
end

function Conductor:updateTime()
    self.time = math.clamp(self.source:tell() - self.offset, 0,
                           self.source:getDuration())
end

function Conductor:updateStep()
    self.currentStep = math.floor(self.time / self.stepCrochet)
    self.currentBeat = math.floor(self.currentStep / 4)
end

function Conductor:update(dt)
    if self.source:isPlaying() then
        self:updateTime()

        local t = self.lastTime + self.stepCrochet
        if self.time > t then
            self:updateStep()
            self.lastTime = t

            if self.onStep then self.onStep(self.currentStep) end
            if self.onBeat and self.currentBeat == self.currentStep / 4 then
                self.onBeat(self.currentBeat)
            end
        end
    end
end

function Conductor:play()
    self.source:play()
    -- if self.time <= 0 then
    --     if self.onStep then self.onStep(self.currentStep) end
    --     if self.onBeat then self.onBeat(self.currentBeat) end
    -- end
end

function Conductor:pause()
    self.source:pause()
    self:updateTime()
    self:updateStep()
end

function Conductor:destroy() self.source:stop() end

return Conductor
