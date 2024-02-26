local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local NoteHitEvent = CancellableEvent:extend("NoteHitEvent")

function NoteHitEvent:new()
	NoteHitEvent.super.new(self)

	self.hideRating = false
	self.hideScore = false
	self.hideCombo = false
end

function NoteHitEvent:cancelRating()
	self.hideRating = true
end

function NoteHitEvent:cancelScore()
	self.hideScore = true
end

function NoteHitEvent:cancelCombo()
	self.hideCombo = true
end

return NoteHitEvent
