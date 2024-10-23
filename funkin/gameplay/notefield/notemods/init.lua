NoteModifier = require "funkin.gameplay.notefield.notemods.notemodifier"

local NoteMods = {
	beat   = require "funkin.gameplay.notefield.notemods.notemodbeat",
	column = require "funkin.gameplay.notefield.notemods.notemodcolumn",
	scale  = require "funkin.gameplay.notefield.notemods.notemodscale",
	scroll = require "funkin.gameplay.notefield.notemods.notemodscroll",
	tipsy  = require "funkin.gameplay.notefield.notemods.notemodtipsy"
}

return NoteMods
