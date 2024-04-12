local NoteModifier = Classic:extend("NoteModifier")

local ocache, prepare = {}
function prepare(o, i, v)
	if v == nil then
		for i, v in pairs(i) do prepare(o, i, v) end
		return
	end
	local c = ocache[o]
	if not c then
		c = {}; ocache[o] = c
	end
	if not c[i] then c[i] = v end
end

NoteModifier.prepare = prepare

function NoteModifier.discard()
	for o, c in pairs(ocache) do
		for i, v in pairs(c) do
			o[i], c[i] = v
		end
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
	self.dontUpdatePercent = false
end

function NoteModifier:update(curBeat)
	if self.dontUpdatePercent then
		self._lastBeat = nil
		return
	end
	if self._lastBeat then
		if self.percent > self.strength then
			self.percent = math.max(self.percent - (curBeat - self._lastBeat) * self.approach, self.strength)
		elseif self.percent < self.strength then
			self.percent = math.min(self.percent + (curBeat - self._lastBeat) * self.approach, self.strength)
		end
	end
	self._lastBeat = curBeat
end

--[[
function NoteModifier:apply(notefield)
	
end

function NoteModifier:applyPath(path, curBeat, pos, notefield, data)
	
end
]]

return NoteModifier
