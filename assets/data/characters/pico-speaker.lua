local animationNotes = {}

function create()
	self:setFrames(paths.getSparrowAtlas('characters/picoSpeaker'))

	self:addAnimByPrefix('shoot1', 'Pico shoot 1', 24, false)
	self:addAnimByPrefix('shoot2', 'Pico shoot 2', 24, false)
	self:addAnimByPrefix('shoot3', 'Pico shoot 3', 24, false)
	self:addAnimByPrefix('shoot4', 'Pico shoot 4', 24, false)
	self:addAnimByIndices('shoot3-loop', 'Pico shoot 3', {50, 51, 52}, 24, true)
	self:addAnimByIndices('shoot1-loop', 'Pico shoot 1', {23, 24, 25}, 24, true)
	self:addAnimByIndices('shoot2-loop', 'Pico shoot 2', {57, 58, 59}, 24, true)
	self:addAnimByIndices('shoot4-loop', 'Pico shoot 4', {50, 51, 52}, 24, true)

	self:addOffset('shoot1', 0, 0)
	self:addOffset('shoot2', -1, -128)
	self:addOffset('shoot3', 412, -64)
	self:addOffset('shoot4', 439, -19)
	self:addOffset('shoot3-loop', 412, -64)
	self:addOffset('shoot1-loop', 0, 0)
	self:addOffset('shoot2-loop', 1, -128)
	self:addOffset('shoot4-loop', 439, -19)

	self.x = self.x + 120
	self.y = self.y + -125
	self.icon = "pico"
	self.cameraPosition = {x = -310, y = 100}

	loadMappedAnims()
end

function loadMappedAnims()
	local swagShit = paths.getJSON("songs/"..PlayState.curSong.."/picospeaker").song

	local notes = swagShit.notes

	for _, section in ipairs(notes) do
		for _, idk in ipairs(section.sectionNotes) do
			table.insert(animationNotes, idk)
		end
	end
	table.sort(animationNotes, sortAnims)
end

function sortAnims(a, b) return a[1] < b[1] end

function update(dt)
	if #animationNotes > 0 and PlayState.songPosition > animationNotes[1][1] then
		local noteData = 1

		if animationNotes[1][2] > 2 then
			noteData = 3
		end

		noteData = noteData + love.math.random(0, 1)

		self:playAnim('shoot'..noteData, true)
		table.remove(animationNotes, 1)
	end
end