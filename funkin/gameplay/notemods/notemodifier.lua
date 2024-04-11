local NoteModifier = Classic:extend("NoteModifier")

local ocache, prepare = {}
function prepare(o, i, v)
	local c = ocache[o]
	if not c then c = {}; ocache[o] = c end
	if v == nil then for i, v in pairs(i) do prepare(o, i, v) end
	elseif not c[i] then c[i] = v end
end
NoteModifier.prepare = prepare

function NoteModifier.discard()
	for o, c in pairs(ocache) do
		for i, v in pairs(c) do o[i] = v end
	end
end

function NoteModifier.reset()
	table.clear(ocache)
end

function NoteModifier:new()
	self.approach = 1 --in beats
	self.strength = 1
	self.time = 0
	self.duration = nil
	self.percent = 0
	self._lastBeat = 0
end

function NoteModifier:update(curBeat)
	self.percent, self._lastBeat = math.clamp(self.percent + (curBeat - self._lastBeat), 0, self.strength), curBeat
end

--[[
function NoteModifier:apply(notefield)
	
end

function NoteModifier:applyPath(path, curBeat, pos, notefield, column)
	
end
]]

return NoteModifier