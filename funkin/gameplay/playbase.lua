local PlayBase = Classic:extend("PlayBase")
-- !! INTENTED TO BE IMPLEMENTED, NOT EXTENDED

-- this handles basic gameplay logic: conductor, notefields and input
-- can be implemented on states, substates, or groups

function PlayBase:setupConductorSong(song)
	self.startingSong = true
	local songName = paths.formatToSongPath(song.song)

	local conductor = Conductor():setSong(song)
	conductor.onStep = bind(self, self.step)
	conductor.onBeat = bind(self, self.beat)
	conductor.onSection = bind(self, self.section)

	if game.sound.music then game.sound.music:reset(true) end
	game.sound.loadMusic(paths.getInst(songName))
	game.sound.music:setLooping(false)
	game.sound.music:setVolume(ClientPrefs.data.musicVolume / 100)
	game.sound.music.onComplete = function() if self.endSong then self:endSong() end end

	return conductor
end

function PlayBase:generateNotefields(keys, songName, camera)
	Note.defaultSustainSegments = 3
	NoteModifier.reset()

	local playerVocals, enemyVocals, volume =
		paths.getVoices(songName, self.SONG.player1, true)
		or paths.getVoices(songName, "Player", true)
		or paths.getVoices(songName, nil, true),
		paths.getVoices(songName, self.SONG.player2, true)
		or paths.getVoices(songName, "Opponent", true),
		ClientPrefs.data.vocalVolume / 100
	if playerVocals then
		playerVocals = game.sound.load(playerVocals)
		playerVocals:setVolume(volume)
	end
	if enemyVocals then
		enemyVocals = game.sound.load(enemyVocals)
		enemyVocals:setVolume(volume)
	end

	local y, volume = game.height / 2, ClientPrefs.data.vocalVolume / 100
	self.playerNotefield = Notefield(0, y, keys, self.SONG.skin,
		self.boyfriend, playerVocals, self.SONG.speed)
	self.enemyNotefield = Notefield(0, y, keys, self.SONG.skin,
		self.dad, enemyVocals, self.SONG.speed)
	self.playerNotefield.bot, self.enemyNotefield.bot,
	self.enemyNotefield.canSpawnSplash = ClientPrefs.data.botplayMode, true, false
	self.notefields = {self.playerNotefield, self.enemyNotefield}

	if camera then
		camera = {camera}
		self.playerNotefield.cameras, self.enemyNotefield.cameras = camera, camera
	end

	self:centerNotefields()

	for _, n in ipairs(self.SONG.notes.enemy) do
		self:generateNote(self.enemyNotefield, n)
	end
	for _, n in ipairs(self.SONG.notes.player) do
		self:generateNote(self.playerNotefield, n)
	end

	self:add(self.enemyNotefield)
	self:add(self.playerNotefield)
end

function PlayBase:updateInput(dt)
	local time = self.conductor.time / 1000
	local missOffset = time - Note.safeZoneOffset / 1.25
	for _, notefield in ipairs(self.notefields) do
		if notefield.is then
			notefield.time, notefield.beat = time, self.conductor.currentBeatFloat

			local isPlayer, sustainHitOffset, noSustainHit, sustainTime,
			noteTime, lastPress, dir, fullyHeldSustain, char, hasInput, resetVolume =
				not notefield.bot, 0.25 / notefield.speed
			for _, note in ipairs(notefield:getNotes(time, nil, true)) do
				noteTime, lastPress, dir, noSustainHit, char =
					note.time, note.lastPress, note.direction,
					not note.wasGoodSustainHit, note.character or notefield.character
				hasInput = not isPlayer or controls:down(self.keysControls[dir])

				if note.wasGoodHit then
					sustainTime = note.sustainTime

					if hasInput then
						-- sustain hitting
						note.lastPress = time
						lastPress = time
						resetVolume = true
					else
						lastPress = note.lastPress
					end

					if not note.wasGoodSustainHit and lastPress ~= nil then
						if noteTime + sustainTime - sustainHitOffset <= lastPress then
							-- end of sustain hit
							fullyHeldSustain = noteTime + sustainTime <= lastPress
							if fullyHeldSustain or not hasInput then
								self:goodSustainHit(note, time, fullyHeldSustain)
								noSustainHit = false
							end
						elseif not hasInput and isPlayer and noteTime <= time then
							-- early end of sustain hit (no full score)
							self:goodSustainHit(note, time)
							noSustainHit, note.tooLate = false, true
							notefield.lastSustain = nil
						end
					end

					if noSustainHit and hasInput and char then
						char.lastHit = self.conductor.time
					end
				elseif isPlayer then
					if noSustainHit
						and (lastPress or noteTime) <= missOffset then
						-- miss note
						self:miss(note)
					end
				elseif noteTime <= time then
					-- botplay hit
					self:goodNoteHit(note, time)
				end
			end

			if resetVolume then
				local vocals = notefield.vocals or self.playerNotefield.vocals
				if vocals then vocals:setVolume(ClientPrefs.data.vocalVolume / 100) end
			end
		end
	end
end

function PlayBase:centerNotefields()
	self.playerNotefield:screenCenter("x")
	self.enemyNotefield:screenCenter("x")

	if self.middleScroll then
		for _, notefield in ipairs(self.notefields) do
			if notefield.is and notefield ~= self.playerNotefield then
				notefield.visible = false
			end
		end
	else
		self.playerNotefield.x = self.playerNotefield.x + game.width / 4
		self.enemyNotefield.x = self.enemyNotefield.x - game.width / 4

		for _, notefield in ipairs(self.notefields) do
			if notefield.is then notefield.visible = true end
		end
	end
end

function PlayBase:generateNote(notefield, n)
	if n.t >= self.startPos then
		local sustainTime = n.l or 0
		if sustainTime > 0 then
			sustainTime = math.max(sustainTime / 1000, 0.125)
		end
		local note = notefield:makeNote(n.t / 1000, n.d % 4, sustainTime, n.k)
		if n.gf then note.character = self.gf end
	end
end

function PlayBase:getRating(a, b)
	local diff = math.abs(a - b)
	for _, r in ipairs(self.ratings) do
		if diff <= (r.time < 0 and Note.safeZoneOffset or r.time) then return r end
	end
end

function PlayBase:getKeyFromEvent(controls)
	for _, control in pairs(controls) do
		local dir = self.inputDirections[control]
		if dir ~= nil then return dir end
	end
	return -1
end

function PlayBase:onKeyPress(key, type, scancode, isrepeat, time)
	if self.substate and not self.persistentUpdate then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)
	if key < 0 then return end

	local fixedKey, offset = key + 1,
		(time - self.lastTick) * game.sound.music:getActualPitch()
	for _, notefield in ipairs(self.notefields) do
		if notefield.is and not notefield.bot then
			time = notefield.time + offset
			local hitNotes, hasSustain = notefield:getNotes(time, key)
			local l = #hitNotes
			if l == 0 then
				local receptor = notefield.receptors[fixedKey]
				if receptor then
					receptor:play(hasSustain and "confirm" or "pressed")
				end
				if not hasSustain and not ClientPrefs.data.ghostTap then
					self:miss(notefield, key)
				end
			else
				-- remove stacked notes (this is dedicated to spam songs)
				local i, firstNote, note = 2, hitNotes[1]
				while i <= l do
					note = hitNotes[i]
					if note and math.abs(note.time - firstNote.time) < 0.01 then
						notefield:removeNote(note)
					else
						break
					end
					i = i + 1
				end
				self:goodNoteHit(firstNote, time)
			end
		end
	end
end

function PlayBase:onKeyRelease(key, type, scancode, time)
	if self.substate and not self.persistentUpdate then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)

	if key < 0 then return end

	local fixedKey = key + 1
	for _, notefield in ipairs(self.notefields) do
		if notefield.is and not notefield.bot then
			self:resetStroke(notefield, key)
		end
	end
end

function PlayBase:resetStroke(notefield, dir, doPress)
	local receptor = notefield.receptors
	if receptor then
		receptor = receptor[dir + 1]
		receptor:play((doPress and not notefield.bot)
			and "pressed" or "static")
	end
end

-- these can be overwritten to implement your own logic on a state
function PlayBase:goodNoteHit(note, time)
	local notefield, dir, isSustain =
		note.parent, note.direction, note.sustain

	if not note.wasGoodHit then
		note.wasGoodHit = true

		local vocals = notefield.vocals or self.playerNotefield.vocals
		if vocals then vocals:setVolume(ClientPrefs.data.vocalVolume / 100) end

		notefield.lastSustain = isSustain and note or nil
		if isSustain then notefield:removeNote(note) end

		local rating = self:getRating(note.time, time)
		local receptor = notefield.receptors[dir + 1]

		if receptor then
			receptor:play("confirm", true)
			if ClientPrefs.data.noteSplash and notefield.canSpawnSplash and rating.splash then
				receptor:spawnSplash()
			end
			receptor.holdTime = not isSustain and 0.2 or 0
		end
		if isSustain then receptor:spawnCover(note) end
	end
end

function PlayBase:goodSustainHit(note, time, fullyHeldSustain)
	local notefield, dir, fullScore =
		note.parent, note.direction, fullyHeldSustain ~= nil
	if not note.wasGoodSustainHit then
		note.wasGoodSustainHit = true

		self:resetStroke(notefield, dir, fullyHeldSustain)
		if fullScore then notefield:removeNote(note) end
	end
end

-- dir can be nil for non-ghost-tap
function PlayBase:miss(note, dir)
	local ghostMiss = dir ~= nil
	if not ghostMiss then dir = note.direction end

	local notefield = ghostMiss and note or note.parent
	if (ghostMiss or not note.tooLate) then
		if not ghostMiss then note.tooLate = true end
		if notefield.vocals then notefield.vocals:setVolume(0) end

		util.playSfx(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)),
			love.math.random(1, 2) / 10)
	end
end

function PlayBase:resyncVocals()
	local time, rate = game.sound.music:tell(), math.max(self.playback, 1)
	if math.abs(time - self.conductor.time / 1000) > 0.015 * rate then
		self.conductor.time = time * 1000
	end
	local maxDelay, vocals, lastVocals = 0.0091 * rate
	for _, notefield in ipairs(self.notefields) do
		vocals = notefield.vocals
		if vocals and lastVocals ~= vocals and vocals:isPlaying()
			and math.abs(time - vocals:tell()) > maxDelay then
			vocals:seek(time)
			lastVocals = vocals
		end
	end
	lastVocals = nil
end

function PlayBase:pauseSong()
	game.sound.music:pause()
	local lastVocals
	for _, notefield in ipairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals:pause()
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil

	self.paused = true
end

function PlayBase:playSong(daTime)
	self:setSongPlayback(self.playback or 1)

	if daTime then game.sound.music:seek(daTime) end
	game.sound.music:play()

	local time, lastVocals = game.sound.music:tell()
	for _, notefield in ipairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals:seek(time)
			notefield.vocals:play()
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil
	PlayState.conductor.time = time * 1000

	self.paused = false
end

function PlayBase:setSongPlayback(playback)
	game.sound.music:setPitch(playback)
	local lastVocals
	for _, notefield in ipairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals:setPitch(playback)
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil

	return playback
end

return PlayBase
