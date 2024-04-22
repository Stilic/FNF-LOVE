local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local MissEvent = CancellableEvent:extend("MissEvent")

function MissEvent:new(notefield, direction, note)
	MissEvent.super.new(self)

	self.muteVocals = true
	self.cancelledAnim = false
	self.cancelledSadGF = false

	self.notefield = notefield
	self.direction = direction
	self.note = note
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
