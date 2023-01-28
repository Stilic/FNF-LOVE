local Conductor = Object:extend()

function Conductor:new()
	self.position = 0

	self.bpm = 100
	self.bpmChangeEvents = {}
	self.crochet = self.calculateCrochet(self.bpm)
	self.stepCrochet = self.crochet / 4
end

return Conductor