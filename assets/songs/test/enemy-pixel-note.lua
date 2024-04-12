function postCreate()
	for _, rep in ipairs(state.enemyReceptors.members) do
		rep:setStyle(rep, "pixel")
	end

	for _, n in ipairs(state.unspawnNotes) do
		if not n.mustPress then
			n:setStyle(n, "pixel")
		end
	end
end
