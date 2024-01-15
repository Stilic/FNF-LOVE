function postCreate()
	for _, rep in ipairs(state.enemyReceptors.members) do
		rep:loadTexture(paths.getImage('skins/pixel/NOTE_assets'))
		rep.width = rep.width / 4
		rep.height = rep.height / 5
		rep:loadTexture(paths.getImage('skins/pixel/NOTE_assets'), true,
			math.floor(rep.width), math.floor(rep.height))

		rep.antialiasing = false
		rep:setGraphicSize(math.floor(rep.width * 6))

		rep:addAnim('static', Receptor.pixelAnim[rep.data + 1][1])
		rep:addAnim('pressed', Receptor.pixelAnim[rep.data + 1][2], 12, false)
		rep:addAnim('confirm', Receptor.pixelAnim[rep.data + 1][3], 24, false)

		rep:updateHitbox()
		rep:play('static')
	end

	for i, n in ipairs(state.unspawnNotes) do
		if not n.mustPress then
			local color = Note.colors[n.data + 1]
			if n.isSustain then
				n:loadTexture(paths.getImage('skins/pixel/NOTE_assetsENDS'))
				n.width = n.width / 4
				n.height = n.height / 2
				n:loadTexture(paths.getImage('skins/pixel/NOTE_assetsENDS'),
					true, math.floor(n.width),
					math.floor(n.height))

				n:addAnim(color .. 'holdend', Note.pixelAnim[n.data + 1][1])
				n:addAnim(color .. 'hold', Note.pixelAnim[n.data + 1][2])
			else
				n:loadTexture(paths.getImage('skins/pixel/NOTE_assets'))
				n.width = n.width / 4
				n.height = n.height / 5
				n:loadTexture(paths.getImage('skins/pixel/NOTE_assets'), true,
					math.floor(n.width), math.floor(n.height))

				n:addAnim(color .. 'Scroll', Note.pixelAnim[n.data + 1][1])
			end
			n:setGraphicSize(math.floor(n.width * 6))
			n.antialiasing = false
			n:updateHitbox()
			n:play(color .. "Scroll")
			n.scrollOffset = {x = 0, y = 0}
			if n.isSustain and n.prevNote then
				n.scrollOffset.x = n.scrollOffset.x + n.width / 2
				n:play(color .. "holdend")
				n:updateHitbox()
				n.scrollOffset.x = n.scrollOffset.x - n.width / 2
				n.scrollOffset.x = n.scrollOffset.x + 30
				if n.prevNote.isSustain then
					n.prevNote:play(Note.colors[n.prevNote.data + 1] .. "hold")
					n.prevNote.scale.y = (n.prevNote.width / n.prevNote:getFrameWidth()) *
						((PlayState.conductor.stepCrotchet / 100) *
							(1.05 / 0.7)) * PlayState.SONG.speed
					n.prevNote.scale.y = n.prevNote.scale.y * 5
					n.prevNote.scale.y = n.prevNote.scale.y * (6 / n.height)
					n.prevNote:updateHitbox()
				end
			end
		end
	end
end

function postGoodNoteHit(n)
	if not n.mustPress then
		local receptor = state.enemyReceptors.members[n.data + 1]
		receptor:centerOffsets()
		receptor:centerOrigin()
	end
end
