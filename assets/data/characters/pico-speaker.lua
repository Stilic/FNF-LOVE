local animationNotes = {}

function create()
	local animChart = Parser.getChart("stress", "picospeaker")
	if not animChart then
		return
	end

	for k, v in ipairs(animChart.notes.player) do table.insert(animChart.notes.enemy, v) end
	table.sort(animChart.notes.enemy, function(a, b) return a.t < b.t end)

	for _, n in ipairs(animChart.notes.enemy) do
		table.insert(animationNotes, n)
	end
end

function update(dt)
	if #animationNotes > 0 and PlayState.conductor.time > animationNotes[1].t then
		local noteData = 1

		if animationNotes[1].d > 2 then noteData = 3 end

		noteData = noteData + love.math.random(0, 1)

		self:playAnim('shoot' .. noteData, true)
		table.remove(animationNotes, 1)
	end
end
