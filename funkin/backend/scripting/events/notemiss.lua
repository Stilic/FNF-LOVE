local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local NoteMissEvent = CancellableEvent:extend("NoteMissEvent")

function NoteMissEvent:new(note, character)
	NoteMissEvent.super.new(self)

	self.cancelledAnim = false
	self.muteVocals = true
	self.cancelledSadGF = false

	self.note = note
	self.character = character
end

function NoteMissEvent:cancelAnim()
	self.cancelledAnim = true
end

function NoteMissEvent:cancelMuteVocals()
	self.muteVocals = false
end

function NoteMissEvent:cancelSadGF()
	self.cancelledSadGF = true
end

return NoteMissEvent
