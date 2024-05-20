local CancellableEvent = require "funkin.backend.scripting.events.cancellable"

local PopUpScoreEvent = CancellableEvent:extend("PopUpScoreEvent")

function PopUpScoreEvent:new()
	PopUpScoreEvent.super.new(self)

	self.hideRating = false
	self.hideScore = false
	self.hideCombo = true
end

function PopUpScoreEvent:cancelRating()
	self.hideRating = true
end

function PopUpScoreEvent:cancelScore()
	self.hideScore = true
end

function PopUpScoreEvent:cancelCombo()
	self.hideCombo = true
end

return PopUpScoreEvent
