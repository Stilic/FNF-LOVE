local function sortByShit(a, b) return a.time < b.time end

local PlayState = State:extend()

PlayState.controlDirs = {
	note_left = 0,
	note_down = 1,
	note_up = 2,
	note_right = 3
}

PlayState.ratings = {
	{name = "sick",
		time = 45,
		score = 350,
		fc = "MFC",
		mod = 1,
		splash = true
	},
	{name = "good",
		time = 90,
		score = 200,
		fc = "GFC",
		mod = 0.7,
		splash = false
	},
	{name = "bad",
		time = 135,
		score = 100,
		fc = "FC",
		mod = 0.4,
		splash = false
	},
	{name = "shit",
		time = 180,
		score = 50,
		mod = 0,
		splash = false
	}
}

PlayState.downscroll = false

function PlayState:enter()
	self.keysPressed = {}
	self.keysUsed = {}

	self.camGame = Camera()
	self.camGame.target = {x = 0, y = 0}
	self.camHUD = Camera()

	Sprite.defaultCamera = self.camGame

	self.receptors = Group()
	self.playerReceptors = Group()
	self.enemyReceptors = Group()

	local rx, ry = 36, 50
	if PlayState.downscroll then ry = push.getHeight() - 100 - ry end
	for i = 0, 3 do
		local rep = Receptor(rx, ry, i, 0)
		rep:init()
		rep:setScrollFactor(0)
		self.receptors:add(rep)
		self.enemyReceptors:add(rep)
	end
	for i = 0, 3 do
		local rep = Receptor(rx, ry, i, 1)
		rep:init()
		rep:setScrollFactor(0)
		self.receptors:add(rep)
		self.playerReceptors:add(rep)
	end

	self.unspawnNotes = {}
	self.allNotes = Group()
	self.notesGroup = Group()
	self.sustainsGroup = Group()

	local song = "hiss-2"
	local chart = paths.getJSON("songs/" .. song .. "/" .. song).song
	PlayState.song = {
		name = chart.name,
		bpm = chart.bpm,
		speed = chart.speed,
		needsVoices = chart.needsVoices,
		stage = chart.stage == nil and "stage" or chart.stage,
		boyfriend = chart.player1 == nil and "bf" or chart.player1,
		dad = chart.player2 == nil and "dad" or chart.player2,
		girlfriend = chart.gfVersion == nil and
			(chart.player3 == nil and "gf" or chart.player3) or chart.gfVersion,
		mustHits = {}
	}

	setMusic(paths.getAudioSource("songs/" .. song .. "/Inst", "stream")):setBPM(chart.bpm)
	PlayState.songPosition = -music.crochet * 5
	if chart.needsVoices then
		self.vocals = paths.getAudioSource("songs/" .. song .. "/Voices", "stream")
	end

	for i, s in ipairs(chart.notes) do
		if s ~= nil and s.sectionNotes ~= nil then
			table.insert(PlayState.song.mustHits, s.mustHitSection)
			for _, n in ipairs(s.sectionNotes) do
				local daStrumTime = n[1]
				local daNoteData = n[2] % 4
				local gottaHitNote = s.mustHitSection
				if n[2] > 3 then gottaHitNote = not gottaHitNote end

				local oldNote
				if #self.unspawnNotes > 0 then
					oldNote = self.unspawnNotes[#self.unspawnNotes]
				end

				local note = Note(daStrumTime, daNoteData, oldNote)
				note.mustPress = gottaHitNote
				if n[3] ~= nil and n[3] > 0 then
					note.sustainLength = math.round(n[3] / music.stepCrochet) * music.stepCrochet
				end
				note.altNote = n[4]
				note:setScrollFactor(0)
				table.insert(self.unspawnNotes, note)

				if note.sustainLength > 0 then
					local susLength = note.sustainLength / music.stepCrochet
					if susLength > 0 then
						for susNote = 0, math.max(math.round(susLength), 2) do
							oldNote = self.unspawnNotes[#self.unspawnNotes]

							local sustain = Note(
								daStrumTime + music.stepCrochet * (susNote + 1),
								daNoteData,
								oldNote,
								true
							)
							sustain.mustPress = gottaHitNote
							sustain:setScrollFactor(0)
							table.insert(self.unspawnNotes, sustain)
						end
					end
				end
			end
		else
			table.insert(PlayState.song.mustHits, nil)
		end
	end
	table.sort(self.unspawnNotes, sortByShit)

	self.stage = Stage(PlayState.song.stage)
	self:add(self.stage)

	self.camFollow = {x = 0, y = 0}
	self.camZooming = false

	self.camGame.zoom = self.stage.camZoom

	self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y, self.song.girlfriend, false)
	self.gf:setScrollFactor(0.95)

	self.boyfriend = Character(self.stage.boyfriendPos.x, self.stage.boyfriendPos.y, self.song.boyfriend, true)
	self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y, self.song.dad, false)

	self:add(self.gf)
	self:add(self.boyfriend)
	self:add(self.dad)

	self.judgeSpr = Sprite()
	self:add(self.judgeSpr)

	self.judgeSpr:setScrollFactor(0)
	self.judgeSprTimer = Timer.new()

	self:add(self.receptors)
	self:add(self.sustainsGroup)
	self:add(self.notesGroup)

	for _, o in ipairs({
		self.judgeSpr, self.receptors, self.notesGroup, self.sustainsGroup
	}) do o.camera = self.camHUD end

	self.bindedKeyPress = function(...)
		self:onKeyPress(...)
	end
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = function(...)
		self:onKeyRelease(...)
	end
	controls:bindRelease(self.bindedKeyRelease)
end

function PlayState:update(dt)
	if not isSwitchingState and self.startedSong and music:isFinished() then
		switchState(TitleState())
	end

	local lerpVal = 0.04 * 60 * dt
	self.camGame.target.x, self.camGame.target.y = math.lerp(
		self.camGame.target.x,
		self.camFollow.x, lerpVal
	),
	math.lerp(
		self.camGame.target.y,
		self.camFollow.y, lerpVal
	)

	local mustHit = self:getCurrentMustHit()
	if mustHit ~= nil then
		if not mustHit then
			local midpoint = self.dad:getMidpoint()
			self.camFollow.x, self.camFollow.y =
				midpoint.x + 150 + self.dad.cameraPosition.x + self.stage.dadCam.x,
				midpoint.y - 100 + self.dad.cameraPosition.y + self.stage.dadCam.y
		else
			local midpoint = self.boyfriend:getMidpoint()
			self.camFollow.x, self.camFollow.y =
				midpoint.x - 100 - self.boyfriend.cameraPosition.x - self.stage.boyfriendCam.x,
				midpoint.y - 100 + self.boyfriend.cameraPosition.y + self.stage.boyfriendCam.y
		end
	end

	if self.camZooming then
		local ratio = 0.05 * 60 * dt
		self.camGame.zoom = math.lerp(self.camGame.zoom, self.stage.camZoom, ratio)
		self.camHUD.zoom = math.lerp(self.camHUD.zoom, 1, ratio)
	end

	PlayState.songPosition = PlayState.songPosition + 1000 * dt
	if not self.startedSong and PlayState.songPosition >= 0 then
		self.startedSong = true
		music:play()
	if self.vocals then self.vocals:play() end
		self:resync()
	end

	if self.unspawnNotes[1] then
		local time = 2000
		if PlayState.song.speed < 1 then
			time = time / PlayState.song.speed
		end
		while #self.unspawnNotes > 0 and self.unspawnNotes[1].time -
			PlayState.songPosition < time do
			local n = table.remove(self.unspawnNotes, 1)
			self.allNotes:add(n)
			local grp = n.isSustain and self.sustainsGroup or self.notesGroup
			grp:add(n)
			grp:sort(sortByShit)
		end
	end

	local ogCrochet = (60 / PlayState.song.bpm) * 1000
	local ogStepCrochet = ogCrochet / 4
	for i, n in ipairs(self.allNotes.members) do
		if not n.mustPress and not n.wasGoodHit and
			((not n.isSustain and n.time <= PlayState.songPosition) or
				(n.isSustain and n.canBeHit)) then self:goodNoteHit(n) end

		local time = n.time
		if n.isSustain and PlayState.song.speed ~= 1 then
			time = time - ogStepCrochet + ogStepCrochet / PlayState.song.speed
		end

		local r = (n.mustPress and self.playerReceptors or self.enemyReceptors).members[n.data + 1]
		local sy = r.y + n.scrollOffset.y

		n.x = r.x + n.scrollOffset.x
		n.y = sy - (PlayState.songPosition - time) * (0.45 * PlayState.song.speed) * (PlayState.downscroll and -1 or 1)

		if n.isSustain then
			n.flipY = PlayState.downscroll
			if n.flipY then
				if n.isSustainEnd then
					n.y = n.y + (n.height / 4.1) * (ogCrochet / 400) * 1.5 * PlayState.song.speed + 46 *
						(PlayState.song.speed - 1) - 46 * (1 - ogCrochet / 600) * PlayState.song.speed
				end
				n.y = n.y + Note.swagWidth / 2 - 60.5 * (PlayState.song.speed - 1) + 27.5 *
					(PlayState.song.bpm / 100 - 1) * (PlayState.song.speed - 1)
			else
				n.y = n.y + Note.swagWidth / 10
			end

			if n.wasGoodHit or n.prevNote.wasGoodHit then
				local center = sy + Note.swagWidth / 2
				local vert = center - n.y
				if PlayState.downscroll then
					if n.y - n.offset.y + n.height >= center then
						n.clipRect = {
							x = 0,
							y = 0,
							width = n.width,
							height = vert
						}
					end
				elseif n.y + n.offset.y <= center then
					n.clipRect = {
						x = 0,
						y = vert,
						width = n.width,
						height = n.height - vert
					}
				end
			end
		end

		if PlayState.songPosition > 350 / PlayState.song.speed + n.time then
			self:removeNote(n)
		end
	end

	for d, i in ipairs(Note.directions) do
		local input = "note_" .. i
		local press, hold, release = controls:pressed(input),
									 controls:down(input),
									 controls:released(input)

		local noteList = {}
		for _, n in ipairs(self.allNotes.members) do
			if not n.isSustain then
				if press and n.canBeHit and n.mustPress and not n.wasGoodHit and
					not n.tooLate and n.data + 1 == d then
					table.insert(noteList, n)
				end
			elseif hold and n.canBeHit and n.mustPress and not n.wasGoodHit and
				not n.tooLate and n.data + 1 == d then
				self:goodNoteHit(n)
			end
		end

		if #noteList > 0 then
			table.sort(noteList, sortByShit)

			local epicList, done = {}, false
			for _, n in ipairs(noteList) do
				for _, dn in ipairs(epicList) do
					if math.abs(dn.time - n.time) >= 1 then
						done = true
						break
					end
				end
				if not done then
					self:goodNoteHit(n)
					table.insert(epicList, n)
				else
					break
				end
			end
		end

		local r = self.playerReceptors.members[d]
		if r then
			if press and r.curAnim.name ~= "confirm" then
				r:play("pressed")
			end
			if release then r:play("static") end
		end

		if release then self.boyfriend.holding = false end
	end

	self.judgeSprTimer:update(dt)

	PlayState.super.update(self, dt)
end

-- CAN RETURN NIL!!
function PlayState:getCurrentMustHit()
	return PlayState.song.mustHits[math.floor(music.step / 16) + 1]
end

function PlayState:inputPress(key)
	local noteList, canMiss = {}, false

	for _, n in ipairs(self.allNotes.members) do
		if n.mustPress and not n.tooLate then
			if not n.isSustain and not n.wasGoodHit then
				if not n.canBeHit and n:checkDiff(PlayState.songPosition) then n:update(0) end
				if n.canBeHit then
					if n == key then table.insert(noteList, n) end
					canMiss = true
				end
			elseif n.isSustain and  n.noteData == key and ((n.wasGoodHit or n.prevNote.wasGoodHit) and
				(n.parentNote ~= nil and not n.parent.hasMissed and n.parent.wasGoodHit))
			then
				table.insert(noteList, n)
			end
		end
	end

	--[[
	if #noteList > 0 then
		table.sort(noteList, sortByShit)

			local epicList, done = {}, false
			for _, n in ipairs(noteList) do
				for _, dn in ipairs(epicList) do
					if math.abs(dn.time - n.time) >= 1 then
						done = true
						break
					end
				end
				if not done then
					self:goodNoteHit(n)
					table.insert(epicList, n)
				else
					break
				end
			end
		end]]
end

function PlayState:inputRelease(key)

end

function PlayState:onKeyPress(key, type)
	local controls = controls:getControlsFromSource(type .. ':' .. key)
	if not controls then return end

	local key = self:getKeyFromEvent(controls)
	if key >= 0 then
		print(key, music.time)
		--self:inputPress(key)
	end
end

function PlayState:onKeyRelease(key, type)
	local controls = controls:getControlsFromSource(type .. ':' .. key)
	if not controls then return end

	local key = self:getKeyFromEvent(controls)
	if key >= 0 then
		--self:inputRelease(key)
	end
end

function PlayState:getKeyFromEvent(controls)
	for _, control in next, controls do
		if PlayState.controlDirs[control] then return PlayState.controlDirs[control] end
	end
	return -1
end

function PlayState:goodNoteHit(n)
	if not n.wasGoodHit then
		n.wasGoodHit = true

		local r =
			(n.mustPress and self.playerReceptors or self.enemyReceptors).members[n.data +
				1]
		if r then
			r:play("confirm", true)
			if not n.mustPress then
				local time = 0.175
				if n.isSustain and not n.curAnim.name:endsWith("end") then
					time = time * 2
				end
				r.confirmTimer = time
			end
		end

		local char = n.mustPress and self.boyfriend or self.dad
		char:playAnim("sing" .. string.upper(Note.directions[n.data + 1]), true)
		char.lastHit = PlayState.songPosition
		char.holding = n.isSustain and not n.isSustainEnd

		if not n.mustPress then self.camZooming = true end

		if not n.isSustain then
			if n.mustPress then
				local diff = math.abs(n.time - PlayState.songPosition)
				local rating
				for i = 1, #PlayState.ratings - 1 do
					local r = PlayState.ratings[i]
					if diff <= r.time then
						rating = r
						break
					end
				end
				if not rating then
					rating = PlayState.ratings[#PlayState.ratings - 1]
				end

				self.judgeSprTimer:clear()
				self.judgeSpr:revive()
				self.judgeSpr:load(
					paths.getImage("skins/normal/" .. rating.name))
				self.judgeSpr.alpha = 1
				self.judgeSpr:setGraphicSize(math.floor(
												 self.judgeSpr.width * 0.7))
				self.judgeSpr:updateHitbox()
				self.judgeSpr:screenCenter("y")
				local w = push.getWidth()
				self.judgeSpr.x = (w - self.judgeSpr.width) * 0.35 + 40
				self.judgeSpr.y = self.judgeSpr.y - 60

				self.judgeSprTimer:tween(0.65, self.judgeSpr,
										 {y = self.judgeSpr.y - 25}, "out-circ")
				self.judgeSprTimer:after(
					(music.crochet + music.stepCrochet * 2) / 1000, function()
						self.judgeSprTimer:tween(music.stepCrochet / 1000,
												 self.judgeSpr, {alpha = 0},
												 "linear", function()
							self.judgeSpr:destroy()
						end)
					end)
			end

			self:removeNote(n)
		end
	end
end

function PlayState:removeNote(n)
	n:destroy()
	self.allNotes:remove(n)
	if n.isSustain then
		self.sustainsGroup:remove(n)
	else
		self.notesGroup:remove(n)
	end
end

function PlayState:resync()
	PlayState.songPosition = music.time
	if self.vocals then self.vocals:seek(PlayState.songPosition / 1000) end
end

function PlayState:beat(b)
	if math.abs(music.time - PlayState.songPosition) > 2 then self:resync() end

	if b % 4 == 0 and self.camZooming and self.camGame.zoom < 1.35 then
		self.camGame.zoom = self.camGame.zoom + 0.015
		self.camHUD.zoom = self.camHUD.zoom + 0.03
	end

	PlayState.super.beat(self, b)
end

function PlayState:leave()
	PlayState.songPosition = nil
	PlayState.super.leave(self)

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)
end

return PlayState
