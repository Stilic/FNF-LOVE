local PlayState = State:extend()
local judgeSpritesGroup

PlayState.controlDirs = {
	note_left = 0,
	note_down = 1,
	note_up = 2,
	note_right = 3
}
PlayState.ratings = {
	{ name = "sick", time = 45,  score = 350, splash = true },
	{ name = "good", time = 90,  score = 200, splash = false },
	{ name = "bad",  time = 125, score = 100, splash = false },
	{ name = "shit", time = 150, score = 50,  splash = false }
}
PlayState.downscroll = false
PlayState.combo = 0

function PlayState.sortByShit(a, b) return a.time < b.time end

function PlayState:enter()
	self.scripts = Script.loadScriptsFromDirectory("scripts/play")
	for _, script in ipairs(self.scripts) do
		script:call("create")
	end

	self.keysPressed = {}

	local song = "swap-chase"
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

	setMusic(paths.getAudio("songs/" .. song .. "/Inst", "stream")):setBPM(
		chart.bpm)
	if chart.needsVoices then
		self.vocals = paths.getAudio("songs/" .. song .. "/Voices", "stream")
	end

	self.unspawnNotes = {}
	self.allNotes = Group()
	self.notesGroup = Group()
	self.sustainsGroup = Group()

	for _, s in ipairs(chart.notes) do
		if s and s.sectionNotes then
			table.insert(PlayState.song.mustHits, s.mustHitSection)
			for _, n in ipairs(s.sectionNotes) do
				local daStrumTime = tonumber(n[1])
				local daNoteData = tonumber(n[2])
				if daStrumTime ~= nil and daNoteData ~= nil then
					daNoteData = daNoteData % 4
					local gottaHitNote = s.mustHitSection
					if n[2] > 3 then gottaHitNote = not gottaHitNote end

					local oldNote
					if #self.unspawnNotes > 0 then
						oldNote = self.unspawnNotes[#self.unspawnNotes]
					end

					local note = Note(daStrumTime, daNoteData, oldNote)
					note.mustPress = gottaHitNote
					note.altNote = n[4]
					note:setScrollFactor(0)
					table.insert(self.unspawnNotes, note)

					if n[3] ~= nil then
						local fixedSus = tonumber(n[3])
						if fixedSus ~= nil and fixedSus > 0 then
							fixedSus = math.round(n[3] / music.stepCrochet)
							note.sustainLength = fixedSus * music.stepCrochet

							for susNote = 0, math.floor(math.max(fixedSus, 1)) do
								oldNote = self.unspawnNotes[#self.unspawnNotes]

								local sustain = Note(daStrumTime + music.stepCrochet * (susNote + 1),
									daNoteData, oldNote, true, note)
								sustain.mustPress = gottaHitNote
								sustain:setScrollFactor(0)
								table.insert(self.unspawnNotes, sustain)
							end
						end
					end
				end
			end
		else
			table.insert(PlayState.song.mustHits, nil)
		end
	end

	table.sort(self.unspawnNotes, PlayState.sortByShit)

	PlayState.songPosition = -music.crochet * 5

	self.camGame = Camera()
	self.camGame.target = { x = 0, y = 0 }
	self.camHUD = Camera()

	Sprite.defaultCamera = self.camGame

	self.receptors = Group()
	self.playerReceptors = Group()
	self.enemyReceptors = Group()
	judgeSpritesGroup = Group()

	local rx, ry = push.getWidth() / 2, 50
	if PlayState.downscroll then ry = push.getHeight() - 100 - ry end
	for i = 0, 1 do
		for j = 0, 3 do
			local rep = Receptor(rx + (push.getWidth() / 4) * (i == 1 and 1 or -1), ry, j, i)
			rep:groupInit()
			self.receptors:add(rep)
			if i == 1 then
				self.playerReceptors:add(rep)
			else
				self.enemyReceptors:add(rep)
			end
		end
	end

	self.stage = Stage(PlayState.song.stage)
	self:add(self.stage)

	self.camFollow = { x = 0, y = 0 }
	self.camZooming = false

	self.camGame.zoom = self.stage.camZoom

	self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
		self.song.girlfriend, false)
	self.gf:setScrollFactor(0.95)

	self.boyfriend = Character(self.stage.boyfriendPos.x,
		self.stage.boyfriendPos.y, self.song.boyfriend, true)
	self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y, self.song.dad,
		false)

	self.stage:add(self.gf)
	self.stage:add(self.boyfriend)
	self.stage:add(self.dad)

	self:add(self.stage.front)

	self.judgeSprTimer = Timer.new()

	self:add(self.receptors)
	self:add(self.sustainsGroup)
	self:add(self.notesGroup)

	for _, o in ipairs({
		self.receptors, self.notesGroup, self.sustainsGroup, judgeSpritesGroup
	}) do o.camera = self.camHUD end

	self.bindedKeyPress = function(...) self:onKeyPress(...) end
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = function(...) self:onKeyRelease(...) end
	controls:bindRelease(self.bindedKeyRelease)

	self.startingSong = true

	for _, script in ipairs(self.scripts) do
		script:call("postCreate")
	end
end

function PlayState:update(dt)
	for _, script in ipairs(self.scripts) do
		script:call("update", dt)
	end

	if not isSwitchingState and self.startedSong and music:isFinished() then
		switchState(TitleState())
	end

	if self.startedSong then
		PlayState.songPosition = music.time
	elseif self.startingSong then
		PlayState.songPosition = PlayState.songPosition + 1000 * dt
		if PlayState.songPosition >= 0 then
			self.startedSong = true
			music:play()
			if self.vocals then self.vocals:play() end
		end
	end

	PlayState.super.update(self, dt)

	self.camGame.target.x, self.camGame.target.y = util.coolLerp(self.camGame.target.x, self.camFollow.x,
		0.04), util.coolLerp(self.camGame.target.y, self.camFollow.y,
		0.04)

	local mustHit = self:getCurrentMustHit()
	if mustHit ~= nil then
		if mustHit then
			local midpoint = self.boyfriend:getMidpoint()
			self.camFollow.x = midpoint.x - 100 - self.boyfriend.cameraPosition.x -
				self.stage.boyfriendCam.x
			self.camFollow.y = midpoint.y - 100 + self.boyfriend.cameraPosition.y +
				self.stage.boyfriendCam.y
		else
			local midpoint = self.dad:getMidpoint()
			self.camFollow.x = midpoint.x + 150 + self.dad.cameraPosition.x +
				self.stage.dadCam.x
			self.camFollow.y = midpoint.y - 100 + self.dad.cameraPosition.y +
				self.stage.dadCam.y
		end
	end

	if self.camZooming then
		self.camGame.zoom = util.coolLerp(self.camGame.zoom, self.stage.camZoom, 0.0475)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 0.0475)
	end

	if self.unspawnNotes[1] then
		local time = 2000
		if PlayState.song.speed < 1 then time = time / PlayState.song.speed end
		while #self.unspawnNotes > 0 and self.unspawnNotes[1].time -
			PlayState.songPosition < time do
			local n = table.remove(self.unspawnNotes, 1)
			local grp = n.isSustain and self.sustainsGroup or self.notesGroup
			self.allNotes:add(n)
			grp:add(n)
		end
	end

	local ogCrochet = (60 / PlayState.song.bpm) * 1000
	local ogStepCrochet = ogCrochet / 4
	for i, n in ipairs(self.allNotes.members) do
		if not n.missed and (n.mustPress and n.isSustain and self.keysPressed[n.data] and n.parentNote and
				not n.parentNote.missed and n.parentNote.wasGoodHit and n.canBeHit) or
			(not n.mustPress and
				((n.isSustain and n.canBeHit) or n.time <= PlayState.songPosition)) then
			self:goodNoteHit(n)
		end

		local time = n.time
		if n.isSustain and PlayState.song.speed ~= 1 then
			time = time - ogStepCrochet + ogStepCrochet / PlayState.song.speed
		end

		local r =
			(n.mustPress and self.playerReceptors or self.enemyReceptors).members[n.data +
			1]
		local sy = r.y + n.scrollOffset.y

		n.x = r.x + n.scrollOffset.x
		n.y = sy - (PlayState.songPosition - time) * (0.45 * PlayState.song.speed) *
			(PlayState.downscroll and -1 or 1)

		if n.isSustain then
			n.flipY = PlayState.downscroll
			if n.flipY then
				if n.flipY then
					if n.isSustainEnd then
						n.y = n.y + (43.5 * 0.7) * (music.stepCrochet / 100 * 1.5 * PlayState.song.speed) - n.height
					end
					n.y = n.y + Note.swagWidth / 2 - 60.5 * (PlayState.song.speed - 1) + 27.5 *
						(PlayState.song.bpm / 100 - 1) * (PlayState.song.speed - 1)
				else
					n.y = n.y + Note.swagWidth / 10
				end
			else
				n.y = n.y + Note.swagWidth / 12
			end

			if (n.wasGoodHit or n.prevNote.wasGoodHit) and
				(not n.mustPress or self.keysPressed[n.data] or n.isSustainEnd) then
				local center = sy + Note.swagWidth / 2
				local vert = center - n.y
				if PlayState.downscroll then
					if n.y - n.offset.y + n:getFrameHeight() * n.scale.y >= center then
						if not n.clipRect then n.clipRect = {} end
						n.clipRect.x, n.clipRect.y = 0, 0
						n.clipRect.width, n.clipRect.height = n:getFrameWidth() * n.scale.x, vert
					end
				elseif n.y + n.offset.y <= center then
					if not n.clipRect then n.clipRect = {} end
					n.clipRect.x, n.clipRect.y = 0, vert
					n.clipRect.width, n.clipRect.height = n:getFrameWidth() * n.scale.x,
						n:getFrameHeight() * n.scale.y - vert
				end
			end
		end

		if PlayState.songPosition > 350 / PlayState.song.speed + n.time then
			if n.mustPress and (n.tooLate or not n.wasGoodHit) and not music:isFinished() then
				self.vocals:setVolume(0)
				PlayState.combo = 0

				if not n.missed and not n.isSustain or not n.parentNote.missed then
					if n.isSustain then
						for _, no in ipairs(n.parentNote.children) do
							no.missed = true
						end
					end
				end

				self.boyfriend:sing(n.data, true, n.isSustain)
			end

			self:removeNote(n)
		end
	end

	self.judgeSprTimer:update(dt)

	for _, script in ipairs(self.scripts) do
		script:call("postUpdate", dt)
	end
end

local ogDraw = PlayState.draw
function PlayState:draw()
	for _, script in ipairs(self.scripts) do
		script:call("draw")
	end
	ogDraw(self)
	for _, script in ipairs(self.scripts) do
		script:call("postDraw")
	end

	for _, judgeSpr in ipairs(judgeSpritesGroup.members) do
		judgeSpr:draw()
	end
end

-- CAN RETURN NIL!!
function PlayState:getCurrentMustHit()
	return PlayState.song.mustHits[math.floor(music.step / 16) + 1]
end

function PlayState:getKeyFromEvent(controls)
	for _, control in next, controls do
		if PlayState.controlDirs[control] then return PlayState.controlDirs[control] end
	end
	return -1
end

function PlayState:onKeyPress(key, type)
	local controls = controls:getControlsFromSource(type .. ':' .. key)
	if not controls then return end
	key = self:getKeyFromEvent(controls)
	if key >= 0 then
		self.keysPressed[key] = true

		local prevSongPos = PlayState.songPosition
		PlayState.songPosition = (music.instance and music.instance:tell() * 1000) or
			music.time or prevSongPos

		local noteList = {}

		for _, n in ipairs(self.notesGroup.members) do
			if not n.missed and n.mustPress and not n.isSustain and not n.tooLate and not n.wasGoodHit then
				if not n.canBeHit and n:checkDiff(PlayState.songPosition) then n:update(0) end
				if n.canBeHit and n.data == key then table.insert(noteList, n) end
			end
		end

		if #noteList > 0 then
			table.sort(noteList, PlayState.sortByShit)
			local coolNote = table.remove(noteList, 1)

			for _, n in next, noteList do
				if n.time - coolNote.time < 2 then
					self:removeNote(n)
				end
			end

			self:goodNoteHit(coolNote)
		end

		PlayState.songPosition = prevSongPos

		local r = self.playerReceptors.members[key + 1]
		if r and r.curAnim.name ~= "confirm" then r:play("pressed") end
	end
end

function PlayState:onKeyRelease(key, type)
	local controls = controls:getControlsFromSource(type .. ':' .. key)
	if not controls then return end
	key = self:getKeyFromEvent(controls)
	if key >= 0 then
		self.keysPressed[key] = false

		local r = self.playerReceptors.members[key + 1]
		if r then
			r:play("static")
			r.confirmTimer = 0
		end
	end
end

function PlayState:goodNoteHit(n)
	if not n.wasGoodHit then
		n.wasGoodHit = true
		self.vocals:setVolume(1)

		local char = (n.mustPress and self.boyfriend or self.dad)
		char:sing(n.data, false, n.isSustain)

		local time = 0
		if not n.mustPress then
			self.camZooming = true
			time = 0.15
			if n.isSustain and not n.isSustainEnd then
				time = time * 2
			end
		end
		(n.mustPress and self.playerReceptors or self.enemyReceptors).members[n.data + 1]:confirm(time)

		if not n.isSustain then
			if n.mustPress then
				local diff, rating = math.abs(n.time - PlayState.songPosition), PlayState.ratings
					[#PlayState.ratings - 1]
				for _, r in next, PlayState.ratings do
					if diff <= r.time then
						rating = r
						break
					end
				end

				PlayState.combo = PlayState.combo + 1
				self:popUpScore(rating)
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

function PlayState:beat(b)
	for _, script in ipairs(self.scripts) do
		script:call("beat", b)
	end

	local time = music.instance:tell()
	if self.vocals and math.abs(self.vocals.instance:tell() - time) * 1000 > 6 then
		self.vocals:seek(time)
	end

	if b % 4 == 0 and self.camZooming and self.camGame.zoom < 1.35 then
		self.camGame.zoom = self.camGame.zoom + 0.015
		self.camHUD.zoom = self.camHUD.zoom + 0.03
	end

	PlayState.super.beat(self, b)

	for _, script in ipairs(self.scripts) do
		script:call("postBeat", b)
	end
end

function PlayState:popUpScore(rating)
	local judgeSpr = Sprite()
	judgeSpr:load(paths.getImage("skins/normal/" .. rating.name))
	judgeSpr.alpha = 1
	--	judgeSpr.camera = self.camHUD
	judgeSpr:setGraphicSize(math.floor(judgeSpr.width * 0.7))
	judgeSpr:updateHitbox()
	judgeSpr:screenCenter("y")
	local w = push.getWidth()
	judgeSpr.x = (w - judgeSpr.width) * 0.35 + 40
	judgeSpr.y = judgeSpr.y - 60
	judgeSpr:setScrollFactor(0)

	judgeSpritesGroup:add(judgeSpr)

	self.judgeSprTimer:tween(.3,
		judgeSpr, {y = judgeSpr.y - 20}, "out-circ")

	Timer.after(.3, function()
		self.judgeSprTimer:tween(.2,
		judgeSpr, {alpha = judgeSpr.alpha - 1}, "linear")
	end)
	Timer.after(.28, function()
		self.judgeSprTimer:tween(.30,
		judgeSpr, {y = judgeSpr.y + 20}, "in-circ")
	end)
	Timer.after(.75, function()
		judgeSpritesGroup:remove(judgeSpr)
		judgeSpr:destroy()
	end)

	local comboStr = string.format("%03d", PlayState.combo)
	local yPosition = judgeSpr.y + judgeSpr.height / 2

	if PlayState.combo >= 10 or PlayState.combo == 0 then

		for i = 1, #comboStr do
			local digit = tonumber(comboStr:sub(i, i)) or 0
			local numScore = Sprite()
			numScore:load(paths.getImage("skins/normal/num" .. digit))
			numScore:setGraphicSize(math.floor(numScore.width * 0.7))
			numScore:updateHitbox()
			numScore.x = (i - 1) * numScore.width + 326
			numScore.y = yPosition + 150
			numScore.alpha = 1
			numScore:setScrollFactor(0)

			local accelY = love.math.random(200, 300) / 10
			local velocY = love.math.random(140, 160) / 5
		
			--[[numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);]]

			self.judgeSprTimer:tween(.30*1.5, numScore, {y = numScore.y - accelY * 1.5}, "out-circ")
			Timer.after(.35*1.5, function()
				self.judgeSprTimer:tween(.2*1.5, numScore, {alpha = numScore.alpha - 1}, "linear")
			end)
			Timer.after(.29*1.5, function()
				self.judgeSprTimer:tween(.28*1.5, numScore, {y = numScore.y + accelY * 1.8}, "in-circ")
			end)
			Timer.after(.75*1.5, function()
				judgeSpritesGroup:remove(numScore)
				numScore:destroy()
			end)

			judgeSpritesGroup:add(numScore)
		end

	end
end

function PlayState:leave()
	for _, script in ipairs(self.scripts) do
		script:call("leave")
	end

	PlayState.songPosition = nil

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	PlayState.super.leave(self)

	for _, script in ipairs(self.scripts) do
		script:call("postLeave")
	end
end

return PlayState
