local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local HoldHitEvent = CancellableEvent:extend("HoldHitEvent")

function HoldHitEvent:new(notefield, note, addScore, rating)
	HoldHitEvent.super.new(self)

	self.unmuteVocals = true

	self.notefield = notefield
	self.note = note
	self.addScore = addScore
	self.rating = rating
end

function HoldHitEvent:cancelUnmuteVocals()
	self.unmuteVocals = false
end

return HoldHitEvent
