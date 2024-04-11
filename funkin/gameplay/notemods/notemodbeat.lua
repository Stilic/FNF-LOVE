local NoteModBeat = NoteModifier:extend("NoteModBeat")

local function getAmplitude(curBeat)
	local beat, amp = curBeat % 1, 0
	if beat <= 0.3 then amp = Timer.tween.sine((0.3 - beat) / 0.3) * 0.3
	elseif beat >= 0.7 then amp = -(1 - Timer.tween.sine(1 - (beat - 0.7) / 0.3)) * 0.3 end
	return amp / 0.3 * (curBeat % 2 >= 1 and -1 or 1)
end
NoteModBeat.getAmplitude = getAmplitude

function NoteModBeat:apply(notefield)
	local beat, width = notefield.beat, notefield.noteWidth
	for _, r in ipairs(notefield.receptors) do
		NoteModifier.prepare(r, "x", r.x); NoteModifier.prepare(r.noteOffsets, "x", r.noteOffsets.x)
		local x = getAmplitude(beat) * width / 2 * self.percent
		r.x, r.noteOffsets.x = r.x + x, r.noteOffsets.x - x
	end
end

function NoteModBeat:applyPath(path, curBeat, pos, notefield, column)
	path.x = path.x +getAmplitude(curBeat) * math.fastcos(pos / 20) * notefield.noteWidth / 2 * self.percent
end

return NoteModBeat