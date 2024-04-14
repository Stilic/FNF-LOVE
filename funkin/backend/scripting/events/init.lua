local Events = {
	Cancellable = require "funkin.backend.scripting.events.cancellable",
	NoteHit = require "funkin.backend.scripting.events.notehit",
	HoldHit = require "funkin.backend.scripting.events.holdhit",
	Miss = require "funkin.backend.scripting.events.miss",
	PopUpScore = require "funkin.backend.scripting.events.popupscore",
	CameraMove = require "funkin.backend.scripting.events.cameramove",
	GameOver = require "funkin.backend.scripting.events.gameover"
}

return Events
