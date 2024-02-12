local CancellableEvent = require "funkin.backend.events.cancellable"

local NoteHitEvent = CancellableEvent:extend("NoteHitEvent")

function NoteHitEvent:new(note, character)
    NoteHitEvent.super.new(self)

    self.cancelledAnim = false
    self.strumGlowCancelled = false

    self.note = note
    self.character = character
end

function NoteHitEvent:cancelAnim()
    self.cancelledAnim = true
end

function NoteHitEvent:cancelStrumGlow()
    self.strumGlowCancelled = true
end

return NoteHitEvent