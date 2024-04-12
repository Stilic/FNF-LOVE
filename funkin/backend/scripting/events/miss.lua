local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local MissEvent = CancellableEvent:extend("MissEvent")

function MissEvent:new(notefield, character)
	MissEvent.super.new(self)

	self.cancelledAnim = false
    self.muteVocals = true
    self.cancelledSadGF = false

	self.character = character
end

function MissEvent:cancelAnim()
	self.cancelledAnim = true
end

function MissEvent:cancelMuteVocals()
	self.muteVocals = false
end

function MissEvent:cancelSadGF()
    self.cancelledSadGF = true
end

return MissEvent
