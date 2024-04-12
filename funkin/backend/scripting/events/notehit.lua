local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local NoteHitEvent = CancellableEvent:extend("NoteHitEvent")

function NoteHitEvent:new(note, character, rating, zooming)
	NoteHitEvent.super.new(self)

	self.cancelledAnim = false
	self.strumGlowCancelled = false
	self.unmuteVocals = true
	self.enableCamZooming = zooming

	self.note = note
	self.character = character
	self.rating = rating
end

function NoteHitEvent:cancelAnim()
	self.cancelledAnim = true
end

function NoteHitEvent:cancelStrumGlow()
	self.strumGlowCancelled = true
end

function NoteHitEvent:cancelUnmuteVocals()
	self.unmuteVocals = false
end

function NoteHitEvent:cancelCamZooming()
	self.enableCamZooming = false
end

return NoteHitEvent
