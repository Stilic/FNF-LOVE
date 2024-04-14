local Events = require "funkin.backend.scripting.events"
local PauseSubstate = require "funkin.substates.pause"

--[[ LIST TODO OR NOTES
	maybe make scripts vars just include conductor itself instead of the properties of conductor
	-- NVM NVM, maybe do make a var conductor but keep props

	rewrite timers. to just be dependancy to loxel,. just rewrite timers with new codes.
]]

---@class PlayState:State
local PlayState = State:extend("PlayState")
PlayState.defaultDifficulty = "normal"

PlayState.controlDirs = {
	note_left = 0,
	note_down = 1,
	note_up = 2,
	note_right = 3
}

PlayState.SONG = nil
PlayState.songDifficulty = ""

PlayState.storyPlaylist = {}
PlayState.storyMode = false
PlayState.storyWeek = ""
PlayState.storyScore = 0
PlayState.storyWeekFile = ""

PlayState.seenCutscene = false

PlayState.pixelStage = false

PlayState.prevCamFollow = nil

-- Charting Stuff
PlayState.chartingMode = false
PlayState.startPos = 0

function PlayState.loadSong(song, diff)
	if type(diff) ~= "string" then diff = PlayState.defaultDifficulty end

	local path = "songs/" .. song .. "/charts/" .. diff
	local data = paths.getJSON(path)

	if data then
		local metadata = paths.getJSON('songs/' .. song .. '/meta')
		PlayState.SONG = data.song
		if metadata then PlayState.SONG.meta = metadata end
	else
		local metadata = paths.getJSON('songs/' .. song .. '/meta')
		if metadata == nil then return false end
		PlayState.SONG = {
			song = song,
			bpm = 150,
			speed = 1,
			needsVoices = true,
			stage = 'stage',
			player1 = 'bf',
			player2 = 'dad',
			gfVersion = 'gf',
			notes = {},
			meta = metadata
		}
	end
	return true
end

function PlayState.getSongName()
	return PlayState.SONG.meta and PlayState.SONG.meta.name or PlayState.SONG.song
end

function PlayState:new(storyMode, song, diff)
	PlayState.super.new(self)

	if storyMode ~= nil then
		PlayState.songDifficulty = diff
		PlayState.storyMode = storyMode
		PlayState.storyWeek = ""
	end

	if song ~= nil then
		if storyMode and type(song) == "table" and #song > 0 then
			PlayState.storyPlaylist = song
			song = song[1]
		end
		if not PlayState.loadSong(song, diff) then
			setmetatable(self, TitleState)
			TitleState.new(self)
		end
	end
end

function PlayState:enter()
	if PlayState.SONG == nil then PlayState.loadSong('test') end
	local songName = paths.formatToSongPath(PlayState.SONG.song)

	local conductor = Conductor():setSong(PlayState.SONG)
	conductor.time = self.startPos - (conductor.crotchet * 5)
	conductor.onStep = bind(self, self.step)
	conductor.onBeat = bind(self, self.beat)
	conductor.onSection = bind(self, self.section)
	PlayState.conductor = conductor

	Note.defaultSustainSegments = 1
	NoteModifier.reset()

	self.scoreFormat = "Score: %score // Combo Breaks: %misses // %accuracy% - %rating"
	self.scoreFormatVariables = {score = 0, misses = 0, accuracy = 0, rating = 0}

	self.timer = Timer.new()

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts", "data/scripts/" .. songName, "songs", "songs/" .. songName)

	if Discord then self:updateDiscordRPC() end

	self.startingSong = true
	self.startedCountdown = false
	self.doCountdownAtBeats = nil
	self.lastCountdownBeats = nil

	self.isDead = false
	GameOverSubstate.resetVars()

	self.usedBotPlay = ClientPrefs.data.botplayMode
	self.downScroll = ClientPrefs.data.downScroll
	self.middleScroll = ClientPrefs.data.middleScroll
	self.playback = 1
	Timer.setSpeed(1)

	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	self.scripts:call("create")

	self.camNotes = Camera() --ActorCamera() Will be changed to ActorCamera once thats class is done
	self.camHUD = Camera()
	self.camOther = Camera()
	if ClientPrefs.data.notesBelowHUD then
		game.cameras.add(self.camNotes, false)
		game.cameras.add(self.camHUD, false)
	else
		game.cameras.add(self.camHUD, false)
		game.cameras.add(self.camNotes, false)
	end
	game.cameras.add(self.camOther, false)

	self.camNotes.bgColor[4] = ClientPrefs.data.backgroundDim / 100

	if game.sound.music then game.sound.music:reset(true) end
	game.sound.loadMusic(paths.getInst(songName))
	game.sound.music:setLooping(false)
	game.sound.music:setVolume(ClientPrefs.data.musicVolume / 100)
	game.sound.music.onComplete = function() self:endSong() end

	if PlayState.SONG.needsVoices or PlayState.SONG.needsVoices == nil then
		local bfVocals, dadVocals =
			paths.getVoices(songName, self.SONG.player1, true) or paths.getVoices(songName, "bf", true),
			paths.getVoices(songName, self.SONG.player2, true)

		if not bfVocals then
			bfVocals, dadVocals = paths.getVoices(songName), paths.getVoices(songName, "dad", true)
		elseif not dadVocals then
			dadVocals = paths.getVoices(songName, "dad")
		end

		if dadVocals then
			self.dadVocals = Sound():load(dadVocals)
			game.sound.list:add(self.dadVocals)
			self.dadVocals:setVolume(ClientPrefs.data.vocalVolume / 100)
		end
		if bfVocals then
			self.vocals = Sound():load(bfVocals)
			game.sound.list:add(self.vocals)
			self.vocals:setVolume(ClientPrefs.data.vocalVolume / 100)
		end
	end

	PlayState.pixelStage = false
	PlayState.SONG.stage = self:loadStageWithSongName(songName)

	self.stage = Stage(PlayState.SONG.stage)
	self:add(self.stage)
	self.scripts:add(self.stage.script)

	PlayState.SONG.gfVersion = self:loadGfWithStage(songName, PlayState.SONG.stage)

	self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
		self.SONG.gfVersion, false)
	self.gf:setScrollFactor(0.95, 0.95)
	self.scripts:add(self.gf.script)

	self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y,
		self.SONG.player2, false)
	self.scripts:add(self.dad.script)

	self.boyfriend = Character(self.stage.boyfriendPos.x,
		self.stage.boyfriendPos.y, self.SONG.player1,
		true)
	self.scripts:add(self.boyfriend.script)

	self:add(self.gf)
	self:add(self.dad)
	self:add(self.boyfriend)

	if self.SONG.player2:startsWith('gf') then
		self.gf.visible = false
		self.dad:setPosition(self.gf.x, self.gf.y)
	end

	self:add(self.stage.foreground)

	self.judgeSprites = Judgement(self.stage.ratingPos.x, self.stage.ratingPos.y)
	self:add(self.judgeSprites)

	self.camFollow = {
		x = 0,
		y = 0,
		set = function(this, x, y)
			this.x = x
			this.y = y
		end
	}
	self:cameraMovement()
	self.camZoom, self.camZoomSpeed, self.camSpeed = self.stage.camZoom or 1, self.stage.camZoomSpeed or 1, self.stage.camSpeed or 1

	if PlayState.prevCamFollow ~= nil then
		self.camFollow:set(PlayState.prevCamFollow.x, PlayState.prevCamFollow.y)
		PlayState.prevCamFollow = nil
	end
	game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
	game.camera:snapToTarget()
	game.camera.zoom = self.stage.camZoom
	self.camZooming = false

	local y, center, keys, skin = game.height / 2, game.width / 2, 4, self.pixelStage and "pixel" or nil
	self.enemyNotefield = Notefield(0, y, keys, skin, self.dad, self.dadVocals)
	self.enemyNotefield.x = math.max(center - self.enemyNotefield:getWidth() / 1.5, math.lerp(0, game.width, 0.25))
	self.playerNotefield = Notefield(0, y, keys, skin, self.boyfriend, self.vocals)
	self.playerNotefield.x = math.min(center + self.playerNotefield:getWidth() / 1.5, math.lerp(0, game.width, 0.75))

	local vocalVolume = ClientPrefs.data.vocalVolume / 100
	self.enemyNotefield.canSpawnSplash, self.enemyNotefield.bot = false, true
	self.enemyNotefield.vocalVolume, self.playerNotefield.vocalVolume = vocalVolume, vocalVolume

	self.enemyNotefield.cameras = {self.camNotes}
	self.playerNotefield.cameras = {self.camNotes}

	self.notefields = {self.enemyNotefield, self.playerNotefield}
	self:generateNotes()

	self:add(self.enemyNotefield)
	self:add(self.playerNotefield)

	self.countdown = Countdown()
	self.countdown:screenCenter()
	self:add(self.countdown)

	self.healthBar = HealthBar(self.boyfriend, self.dad)
	self.healthBar:screenCenter("x").y = game.height * 0.91
	self:add(self.healthBar)

	self.timeArc = ProgressArc(36, game.height - 81, 64, 20,
		{Color.BLACK, Color.WHITE}, 0, game.sound.music:getDuration() / 1000)
	self:add(self.timeArc)

	local fontScore = paths.getFont("vcr.ttf", 17)
	self.scoreText = Text(game.width / 2, self.healthBar.y + 28, "", fontScore, Color.WHITE, "center")
	self.scoreText.outline.width = 1
	self.scoreText.antialiasing = false
	self:add(self.scoreText)

	local songTime = 0
	if ClientPrefs.data.timeType == "left" then
		songTime = game.sound.music:getDuration() - songTime
	end

	local fontTime = paths.getFont("vcr.ttf", 24)
	self.timeText = Text((self.timeArc.x + self.timeArc.width) + 4, 0, util.formatTime(songTime), fontTime, Color.WHITE, "left")
	self.timeText.outline.width = 2
	self.timeText.antialiasing = false
	self.timeText.y = (self.timeArc.y + self.timeArc.width) - self.timeText:getHeight()
	self:add(self.timeText)

	self.botplayText = Text(0, self.timeText.y, 'BOTPLAY MODE',
		fontTime, Color.WHITE)
	self.botplayText.x = game.width - self.botplayText:getWidth() - 36
	self.botplayText.outline.width = 2
	self.botplayText.antialiasing = false
	self.botplayText.visible = self.usedBotPlay
	self:add(self.botplayText)

	for _, o in ipairs({
		self.countdown, self.healthBar, self.timeArc,
		self.scoreText, self.timeText, self.botplayText,
	}) do o.cameras = {self.camHUD} end

	self.score = 0
	self.combo = 0
	self.misses = 0
	self.accuracy = 0
	self.health = 1

	-- for ratings
	self.totalPlayed = 0
	self.totalHit = 0.0
	self.perfects = 0
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0

	if love.system.getDevice() == "Mobile" then
		local w, h = game.width / 4, game.height

		self.buttons = VirtualPadGroup()

		local left = VirtualPad("left", 0, 0, w, h, Color.PURPLE)
		local down = VirtualPad("down", w, 0, w, h, Color.BLUE)
		local up = VirtualPad("up", w * 2, 0, w, h, Color.GREEN)
		local right = VirtualPad("right", w * 3, 0, w, h, Color.RED)

		self.buttons:add(left)
		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(right)
		self.buttons:set({
			fill = "line",
			lined = false,
			blend = "add",
			releasedAlpha = 0,
			cameras = {self.camOther},
			config = {round = {0, 0}}
		})
		self.buttons:disable()
	end

	if self.buttons then self:add(self.buttons) end

	self.keysPressed = {}
	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = bind(self, self.onKeyPress)
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = bind(self, self.onKeyRelease)
	controls:bindRelease(self.bindedKeyRelease)

	self.playerNotefield.hitsoundVolume = ClientPrefs.data.hitSound / 100
	if self.downScroll then
		for _, notefield in ipairs(self.notefields) do notefield.downscroll = true end
		for _, o in ipairs({
			self.healthBar, self.timeArc,
			self.scoreText, self.timeText, self.botplayText
		}) do
			o.y = -o.y + (o.offset.y * 2) + game.height - (
				o.getHeight and o:getHeight() or o.height)
		end
	end

	if self.middleScroll then
		for _, notefield in ipairs(self.notefields) do
			if notefield ~= self.playerNotefield then
				notefield.visible = false
			else
				notefield:screenCenter("x")
			end
		end
	end

	if self.storyMode and not PlayState.seenCutscene then
		PlayState.seenCutscene = true

		local fileExist, cutsceneType
		for i, path in ipairs({
			paths.getMods('data/cutscenes/' .. songName .. '.lua'),
			paths.getMods('data/cutscenes/' .. songName .. '.json'),
			paths.getPath('data/cutscenes/' .. songName .. '.lua'),
			paths.getPath('data/cutscenes/' .. songName .. '.json')
		}) do
			if paths.exists(path, 'file') then
				fileExist = true
				switch(path:ext(), {
					["lua"] = function() cutsceneType = "script" end,
					["json"] = function() cutsceneType = "data" end,
				})
			end
		end
		if fileExist then
			switch(cutsceneType, {
				["script"] = function()
					local cutsceneScript = Script('data/cutscenes/' .. songName)

					cutsceneScript:call("create")
					self.scripts:add(cutsceneScript)
				end,
				["data"] = function()
					local cutsceneData = paths.getJSON('data/cutscenes/' .. songName)

					for i, event in ipairs(cutsceneData.cutscene) do
						self.timer:after(event.time / 1000, function()
							self:executeCutsceneEvent(event.event)
						end)
					end
				end
			})
		else
			self:startCountdown()
		end
	else
		self:startCountdown()
	end
	self:recalculateRating()

	PlayState.super.enter(self)
	collectgarbage()

	self.scripts:call("postCreate")
end

function PlayState:generateNote(n, s)
	local time, col = tonumber(n[1]), tonumber(n[2])
	if time == nil or col == nil or time < self.startPos then return end

	local hit = s.mustHitSection
	if col > 3 then hit = not hit end
	col = col % 4

	local notefield = hit and self.playerNotefield or self.enemyNotefield
	local note = notefield:makeNote(time / 1000, col, (tonumber(n[3]) or 0) / 1000)
	note.type = n[4]
end

function PlayState:generateNotes()
	for _, s in ipairs(PlayState.SONG.notes) do
		if s and s.sectionNotes then
			for _, n in ipairs(s.sectionNotes) do
				self:generateNote(n, s)
			end
		end
	end

	local speed = PlayState.SONG.speed
	self.playerNotefield.speed = speed
	self.enemyNotefield.speed = speed

	table.sort(self.playerNotefield.notes, Conductor.sortByTime)
	table.sort(self.enemyNotefield.notes, Conductor.sortByTime)
end

function PlayState:loadStageWithSongName(songName)
	local curStage = PlayState.SONG.stage
	if curStage == nil then
		if songName == 'test' then
			curStage = 'test'
		elseif songName == 'spookeez' or songName == 'south' or songName == 'monster' then
			curStage = 'spooky'
		elseif songName == 'pico' or songName == 'philly-nice' or songName == 'blammed' then
			curStage = 'philly'
		elseif songName == 'satin-panties' or songName == 'high' or songName == 'milf' then
			curStage = 'limo'
		elseif songName == 'cocoa' or songName == 'eggnog' then
			curStage = 'mall'
		elseif songName == 'winter-horrorland' then
			curStage = 'mall-evil'
		elseif songName == "senpai" or songName == "roses" then
			curStage, PlayState.pixelStage = "school", true
		elseif songName == "thorns" then
			curStage, PlayState.pixelStage = "school-evil", true
		elseif songName == "ugh" or songName == "guns" or songName == "stress" then
			curStage = "tank"
		else
			curStage = "stage"
		end
	end
	return curStage
end

function PlayState:loadGfWithStage(song, stage)
	local gfVersion = PlayState.SONG.gfVersion
	if gfVersion == nil then
		switch(stage, {
			["limo"] = function() gfVersion = "gf-car" end,
			["mall"] = function() gfVersion = "gf-christmas" end,
			["mall-evil"] = function() gfVersion = "gf-christmas" end,
			["school"] = function() gfVersion = "gf-pixel" end,
			["school-evil"] = function() gfVersion = "gf-pixel" end,
			["tank"] = function()
				if song == 'stress' then
					gfVersion = "pico-speaker"
				else
					gfVersion = "gf-tankmen"
				end
			end,
			default = function() gfVersion = "gf" end
		})
	end
	return gfVersion
end

function PlayState:startCountdown()
	if self.buttons then self.buttons:enable() end

	local event = self.scripts:call("startCountdown")
	if event == Script.Event_Cancel then return end

	self.playback = ClientPrefs.data.playback
	Timer.setSpeed(self.playback)

	game.sound.music:setPitch(self.playback)
	if self.vocals then self.vocals:setPitch(self.playback) end
	if self.dadVocals then self.dadVocals:setPitch(self.playback) end

	self.startedCountdown = true
	self.doCountdownAtBeats = (PlayState.startPos / PlayState.conductor.crotchet) - 4

	self.countdown.duration = PlayState.conductor.crotchet / 1000
	self.countdown.playback = 1
	if PlayState.pixelStage then
		self.countdown.data = {
			{sound = "skins/pixel/intro3",  image = nil},
			{sound = "skins/pixel/intro2",  image = "skins/pixel/ready"},
			{sound = "skins/pixel/intro1",  image = "skins/pixel/set"},
			{sound = "skins/pixel/introGo", image = "skins/pixel/go"}
		}
		self.countdown.scale = {x = 7, y = 7}
		self.countdown.antialiasing = false
	end
end

function PlayState:cameraMovement()
	local section = PlayState.SONG.notes[math.max(PlayState.conductor.currentSection + 1, 1)]
	if section ~= nil then
		local target, camX, camY
		if section.gfSection then
			target = "gf"

			local x, y = self.gf:getMidpoint()
			camX = x - (self.gf.cameraPosition.x - self.stage.gfCam.x)
			camY = y - (self.gf.cameraPosition.y - self.stage.gfCam.y)
		elseif section.mustHitSection then
			target = "bf"

			local x, y = self.boyfriend:getMidpoint()
			camX = x - 100 - (self.boyfriend.cameraPosition.x -
				self.stage.boyfriendCam.x)
			camY = y - 100 + (self.boyfriend.cameraPosition.y +
				self.stage.boyfriendCam.y)
		else
			target = "dad"

			local x, y = self.dad:getMidpoint()
			camX = x + 150 + (self.dad.cameraPosition.x +
				self.stage.dadCam.x)
			camY = y - 100 + (self.dad.cameraPosition.y +
				self.stage.dadCam.y)
		end

		local event = self.scripts:event("onCameraMove", Events.CameraMove(target))
		if not event.cancelled then
			self.camFollow:set(camX - event.offset.x, camY - event.offset.y)
		end
	end
end

function PlayState:step(s)
	if Discord and not self.startingSong and self.startedCountdown and game.sound.music:isPlaying() then
		coroutine.wrap(PlayState.updateDiscordRPC)(self)
	end

	self.scripts:set("curStep", s)
	self.scripts:call("step")
	self.scripts:call("postStep")
end

function PlayState:beat(b)
	self.scripts:set("curBeat", b)
	self.scripts:call("beat")

	self.boyfriend:beat(b)
	self.gf:beat(b)
	self.dad:beat(b)

	if not self.startingSong then self.healthBar:scaleIcons(1.2) end

	self.scripts:call("postBeat", b)
end

function PlayState:section(s)
	self.scripts:set("curSection", s)
	self.scripts:call("section")

	local sec = math.max(s + 1, 1)
	if PlayState.SONG.notes[s] and PlayState.SONG.notes[s].changeBPM then
		self.scripts:set("bpm", PlayState.conductor.bpm)
		self.scripts:set("crotchet", PlayState.conductor.crotchet)
		self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)
	end

	if self.camZooming and game.camera.zoom < 1.35 then
		game.camera.zoom = game.camera.zoom + 0.015
		self.camHUD.zoom = self.camHUD.zoom + 0.03
	end

	self.scripts:call("postSection")
end

function PlayState:focus(f)
	if Discord and love.autoPause then self:updateDiscordRPC(not f) end
end

function PlayState:executeCutsceneEvent(event, isEnd)
	switch(event.name, {
		['Camera Position'] = function()
			local xCam, yCam = event.params[1], event.params[2]
			local isTweening = event.params[3]
			local time = event.params[4]
			local ease = event.params[6] .. '-' .. event.params[5]
			if isTweening then
				game.camera:follow(self.camFollow, nil)
				self.timer:tween(time, self.camFollow, {x = xCam, y = yCam}, ease)
			else
				self.camFollow:set(xCam, yCam)
				game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
			end
		end,
		['Camera Zoom'] = function()
			local zoomCam = event.params[1]
			local isTweening = event.params[2]
			local time = event.params[3]
			local ease = event.params[5] .. '-' .. event.params[4]
			if isTweening then
				self.timer:tween(time, game.camera, {zoom = zoomCam}, ease)
			else
				game.camera.zoom = zoomCam
			end
		end,
		['Play Sound'] = function()
			local soundPath = event.params[1]
			local volume = event.params[2]
			local isFading = event.params[3]
			local time = event.params[4]
			local volStart, volEnd = event.params[5], event.params[6]

			local sound = game.sound.play(paths.getSound(soundPath), volume)
			if isFading then sound:fade(time, volStart, volEnd) end
		end,
		['Play Animation'] = function()
			local character = nil
			switch(event.params[1], {
				['bf'] = function() character = self.boyfriend end,
				['gf'] = function() character = self.gf end,
				['dad'] = function() character = self.dad end
			})
			local animation = event.params[2]

			if character then character:playAnim(animation, true) end
		end,
		['End Cutscene'] = function()
			if isEnd then
				self:endSong(true)
			else
				local skipCountdown = event.params[1]
				if skipCountdown then
					PlayState.conductor.time = 0
					self.startedCountdown = true
					if self.buttons then self.buttons:enable() end
				else
					self:startCountdown()
				end
			end
		end,
	})
end

function PlayState:doCountdown(beat)
	if self.lastCountdownBeats == beat then return end
	self.lastCountdownBeats = beat

	if beat > #self.countdown.data then
		self.doCountdownAtBeats = nil
	else
		self.countdown:doCountdown(beat)
	end
end

function PlayState:update(dt)
	dt = dt * self.playback
	self.lastTick = love.timer.getTime()
	self.timer:update(dt)

	if self.startedCountdown then
		PlayState.conductor.time = PlayState.conductor.time + dt * 1000

		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false

			-- reload playback for countdown skip
			self.playback = ClientPrefs.data.playback
			Timer.setSpeed(self.playback)

			game.sound.music:setPitch(self.playback)
			game.sound.music:seek(self.startPos / 1000)
			game.sound.music:play()

			if self.vocals then
				self.vocals:setPitch(self.playback)
				self.vocals:seek(game.sound.music:tell())
				self.vocals:play()
			end
			if self.dadVocals then
				self.dadVocals:setPitch(self.playback)
				self.dadVocals:seek(game.sound.music:tell())
				self.dadVocals:play()
			end

			self.scripts:call("songStart")
		elseif game.sound.music:isPlaying() then
			local rate = math.max(self.playback, 1)
			local time, vocalsTime, dadVocalsTime = game.sound.music:tell(), self.vocals and self.vocals:tell(),
				self.dadVocals and self.dadVocals:tell()
			if PlayState.conductor.lastStep ~= PlayState.conductor.currentStep then
				if vocalsTime and self.vocals:isPlaying() and math.abs(time - vocalsTime) > 0.03 * rate then
					self.vocals:seek(time)
				end
				if dadVocalsTime and self.dadVocals:isPlaying() and math.abs(time - dadVocalsTime) > 0.03 * rate then
					self.dadVocals:seek(time)
				end
			end

			local contime = PlayState.conductor.time / 1000
			if math.abs(time - contime) > 0.015 * rate then
				PlayState.conductor.time = math.lerp(math.clamp(contime, time - rate, time + rate), time, dt * 8) * 1000
			end
		end

		PlayState.conductor:update()

		if self.startingSong and self.doCountdownAtBeats then
			self:doCountdown(math.floor(PlayState.conductor.currentBeatFloat - self.doCountdownAtBeats + 1))
		end
	end

	local noteTime = PlayState.conductor.time / 1000
	for _, notefield in ipairs(self.notefields) do
		notefield.time, notefield.beat = noteTime, PlayState.conductor.currentBeatFloat
		if notefield.bot then
			self:doNotefieldBot(notefield, noteTime)
		end
	end

	self.scripts:call("update", dt)
	PlayState.super.update(self, dt)

	if self.startedCountdown then
		self:cameraMovement()
	end

	if self.camZooming then
		game.camera.zoom = util.coolLerp(game.camera.zoom, self.camZoom, 3, dt * self.camZoomSpeed)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt * self.camZoomSpeed)
	end
	self.camNotes.zoom = self.camHUD.zoom -- ?

	if self.startedCountdown then
		if (self.buttons and game.keys.justPressed.ESCAPE) or controls:pressed("pause") then
			self:tryPause()
		end

		if controls:pressed("debug_1") then
			game.camera:unfollow()
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			if self.dadVocals then self.dadVocals:pause() end
			game.switchState(ChartingState())
		end

		if controls:pressed("debug_2") then
			game.camera:unfollow()
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			if self.dadVocals then self.dadVocals:pause() end
			CharacterEditor.onPlayState = true
			game.switchState(CharacterEditor())
		end

		if controls:pressed("reset") then
			self.health = 0
		end
	end

	self.healthBar.value = self.health

	local songTime = PlayState.conductor.time / 1000
	if ClientPrefs.data.timeType == "left" then
		songTime = game.sound.music:getDuration() - songTime
	end

	if PlayState.conductor.time > 0 and PlayState.conductor.time < game.sound.music:getDuration() * 1000 then
		self.timeText.content = util.formatTime(songTime)
		self.timeArc.tracker = PlayState.conductor.time / 1000
	end

	if self.health <= 0 and not self.isDead then self:tryGameOver() end

	if Project.DEBUG_MODE then
		if game.keys.justPressed.ONE then self.playerNotefield.bot = not self.playerNotefield.bot end
		if game.keys.justPressed.TWO then self:endSong() end
		if game.keys.justPressed.THREE then
			local time = (PlayState.conductor.time + PlayState.conductor.crotchet * (game.keys.pressed.SHIFT and 8 or 4)) / 1000
			PlayState.conductor.time = time * 1000

			game.sound.music:seek(time)
			if self.vocals then self.vocals:seek(time) end
			if self.dadVocals then self.dadVocals:seek(time) end
		end
	end

	self.scripts:call("postUpdate", dt)
end

function PlayState:draw()
	self.scripts:call("draw")
	PlayState.super.draw(self)
	self.scripts:call("postDraw")
end

function PlayState:onSettingChange(category, setting)
	game.camera.freezed = false
	self.camNotes.freezed = false
	self.camHUD.freezed = false

	if category == "gameplay" then
		switch(setting, {
			["downScroll"] = function()
				local downscroll = ClientPrefs.data.downScroll
				if downscroll then
					for _, notefield in ipairs(self.notefields) do notefield.downscroll = true end

					if downscroll ~= self.downScroll then
						for _, o in ipairs({
							self.healthBar, self.timeArc,
							self.scoreText, self.timeText, self.botplayText
						}) do
							o.y = -o.y + (o.offset.y * 2) + game.height - (
								o.getHeight and o:getHeight() or o.height)
						end
					end
				else
					for _, notefield in ipairs(self.notefields) do notefield.downscroll = false end

					if downscroll ~= self.downScroll then
						for _, o in ipairs({
							self.healthBar, self.timeArc,
							self.scoreText, self.timeText, self.botplayText
						}) do
							o.y = (o.offset.y * 2) + game.height - (o.y +
								(o.getHeight and o:getHeight() or o.height))
						end
					end
				end
				self.downScroll = downscroll
			end,
			["middleScroll"] = function()
				self.middleScroll = ClientPrefs.data.middleScroll

				for _, notefield in ipairs(self.notefields) do
					if self.middleScroll then
						if notefield ~= self.playerNotefield then
							notefield.visible = false
						else
							notefield:screenCenter("x")
						end
					else
						local center, keys = game.width / 2, 4
						self.enemyNotefield.x = math.max(center - self.enemyNotefield:getWidth() / 1.5,
							math.lerp(0, game.width, 0.25))
						self.enemyNotefield.visible = true
						self.playerNotefield.x = math.min(center + self.playerNotefield:getWidth() / 1.5,
							math.lerp(0, game.width, 0.75))
					end
				end
			end,
			["botplayMode"] = function()
				self.playerNotefield.bot = ClientPrefs.data.botplayMode
				self.botplayText.visible = ClientPrefs.data.botplayMode
			end,
			["backgroundDim"] = function()
				self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100
			end,
			["notesBelowHUD"] = function()
				local camGameIdx = table.find(game.cameras.list, game.camera)

				table.delete(game.cameras.list, self.camNotes)
				table.delete(game.cameras.list, self.camHUD)

				table.insert(game.cameras.list, camGameIdx + 1,
					ClientPrefs.data.notesBelowHUD and self.camNotes or self.camHUD)
				table.insert(game.cameras.list, camGameIdx + 2,
					ClientPrefs.data.notesBelowHUD and self.camHUD or self.camNotes)
			end,
			["playback"] = function()
				self.playback = ClientPrefs.data.playback
				Timer.setSpeed(self.playback)
				game.sound.music:setPitch(self.playback)
				if self.vocals then self.vocals:setPitch(self.playback) end
				if self.dadVocals then self.dadVocals:setPitch(self.playback) end
			end,
			["timeType"] = function()
				local songTime = PlayState.conductor.time / 1000
				if ClientPrefs.data.timeType == "left" then
					songTime = game.sound.music:getDuration() - songTime
				end
				self.timeText.content = util.formatTime(songTime)
			end,
			["ghostTap"] = function()
				for _, n in ipairs(self.notefields) do
					n.ghostTap = ClientPrefs.data.ghostTap
				end
			end
		})

		local vocalVolume = ClientPrefs.data.vocalVolume / 100
		game.sound.music:setVolume(ClientPrefs.data.musicVolume / 100)
		self.enemyNotefield.vocalVolume, self.playerNotefield.vocalVolume = vocalVolume, vocalVolume
	elseif category == "controls" then
		controls:unbindPress(self.bindedKeyPress)
		controls:unbindRelease(self.bindedKeyRelease)

		self.bindedKeyPress = function(...) self:onKeyPress(...) end
		controls:bindPress(self.bindedKeyPress)

		self.bindedKeyRelease = function(...) self:onKeyRelease(...) end
		controls:bindRelease(self.bindedKeyRelease)
	end

	self.scripts:call("onSettingChange", category, setting)
end

function PlayState:doNotefieldBot(notefield, time)
	local i, notes = 1, notefield.notes
	local size = #notes

	for j = 1, notefield.keys do
		local note = notefield.pressed[j]
		if note then
			if note ~= true then
				local notetime = note.time + math.max(note.sustainTime, 0.14)
				if time >= notetime then notefield:release(notetime, note.direction, true) end
			elseif notefield.lastPress[j] - 0.1 > time then
				notefield:release(time, j - 1, true)
			end
		end
	end

	if size == 0 then return end
	while i <= size do
		local note = notes[i]
		if not note or time < note.time then break end

		if not note.hit and not note.tooLate and not note.ignoreNote then
			PlayState.notefieldPress(notefield, note.time, note.direction)
		end

		local newsize = #notes
		if newsize == size then i = i + 1 end
		size = newsize
	end
end

-- Note can be nil for non-ghosttap
function PlayState:miss(notefield, direction, addScore, note)
	self.scripts:call("miss", notefield, direction, note)

	local event = self.scripts:event("onMiss", Events.Miss(notefield, direction, note))
	if not event.cancelled then
		if event.muteVocals and notefield.vocals then
			notefield.vocals:setVolume(0)
		end

		local char = notefield.character
		if not event.cancelledAnim then
			char:sing(direction, "miss")
		end

		if notefield == self.playerNotefield then
			if not event.cancelledSadGF and self.combo >= 10 and self.gf.__animations.sad then
				self.gf:playAnim('sad', true)
				self.gf.lastHit = PlayState.conductor.time
			end

			self.combo = math.min(self.combo, 0) - 1
			self.health = math.max(self.health - 0.0475, 0)

			self.totalPlayed, self.misses = self.totalPlayed + 1, self.misses + 1
			self.score = self.score + addScore
			self:recalculateRating(); self:popUpScore()
		end
	end

	self.scripts:call("postMiss", notefield, direction, note)
end

function PlayState:goodNoteHit(notefield, note, addScore, rating)
	self.scripts:call("goodNoteHit", notefield, note, rating)

	local isPlayer = notefield == self.playerNotefield
	local event = self.scripts:event("onNoteHit", Events.NoteHit(notefield, note, rating, not isPlayer))
	if not event.cancelled then
		if event.enableCamZooming then
			self.camZooming = true
		end

		if event.unmuteVocals and notefield.vocals then
			notefield.vocals:setVolume(notefield.vocalVolume)
		end

		local char = notefield.character
		if not event.cancelledAnim and char then
			local section, animType = PlayState.SONG.notes[math.max(PlayState.conductor.currentSection + 1, 1)]
			if section and section.altAnim then animType = 'alt' end

			char:sing(note.direction, animType)
			if note.sustain then char.strokeTime = -1 end
		end

		local receptor = notefield.receptors[note.direction + 1]
		if not event.strumGlowCancelled and receptor then
			receptor:play("confirm", true)
			if note.sustain then receptor.strokeTime = -1 end
			if rating and rating.splash then notefield:spawnSplash(note.direction) end
		end

		if isPlayer and not note.ignoreNote then
			self.combo = math.max(self.combo, 0) + 1
			self.health = math.min(self.health + 0.023, 2)

			self.totalPlayed, self.totalHit = self.totalPlayed + 1, self.totalHit + rating.mod
			self.score = self.score + addScore
			self:recalculateRating(rating.name)
		end
	end

	self.scripts:call("postGoodNoteHit", notefield, note, rating)
end

function PlayState:goodHoldHit(notefield, note, addScore, rating)
	self.scripts:call("goodHoldHit", notefield, note, addScore, rating)

	local event = self.scripts:event("onNoteHit", Events.NoteHit(notefield, note, addScore, rating))
	if not event.cancelled then
		if event.unmuteVocals and notefield.vocals then
			notefield.vocals:setVolume(notefield.vocalVolume)
		end

		if notefield == self.playerNotefield and not note.ignoreNote then
			self.health = math.min(self.health + 0.023, 2)

			self.totalPlayed, self.totalHit = self.totalPlayed + 1, self.totalHit + rating.mod
			self.score = self.score + addScore
			self:recalculateRating()
		end
	end

	self.scripts:call("postGoodHoldHit", notefield, note, rating)
end

function PlayState:popUpScore(rating)
	local event = self.scripts:event('onPopUpScore', Events.PopUpScore())
	if not event.cancelled then
		self.judgeSprites.ratingVisible = not event.hideRating
		self.judgeSprites.comboSprVisible = not event.hideCombo
		self.judgeSprites.comboNumVisible = not event.hideScore
		self.judgeSprites:spawn(rating, self.combo)
	end
end

local ratingFormat, noRating = "(%s) %s", "?"
function PlayState:recalculateRating(rating)
	if rating then
		local ratingAdd = rating .. "s"
		self[ratingAdd] = (self[ratingAdd] or 0) + 1
	end

	local ratingStr = noRating
	if self.totalPlayed > 0 then
		local accuracy, class = math.min(1, math.max(0, self.totalHit / self.totalPlayed))
		if accuracy >= 1 then
			class = "X"
		elseif accuracy >= 0.99 then
			class = "S+"
		elseif accuracy >= 0.95 then
			class = "S"
		elseif accuracy >= 0.90 then
			class = "A"
		elseif accuracy >= 0.80 then
			class = "B"
		elseif accuracy >= 0.70 then
			class = "C"
		elseif accuracy >= 0.60 then
			class = "D"
		elseif accuracy >= 0.50 then
			class = "E"
		else
			class = "F"
		end
		self.accuracy = accuracy

		local fc
		if self.misses < 1 then
			if self.bads > 0 or self.shits > 0 then
				fc = "FC"
			elseif self.goods > 0 then
				fc = "GFC"
			elseif self.sicks > 0 then
				fc = "SFC"
			elseif self.perfects > 0 then
				fc = "PFC"
			else
				fc = "FC"
			end
		else
			fc = self.misses >= 10 and "Clear" or "SDCB"
		end

		ratingStr = ratingFormat:format(fc, class)
	end

	self.rating = ratingStr

	local vars = self.scoreFormatVariables
	if not vars then
		vars = table.new(0, 4)
		self.scoreFormatVariables = vars
	end
	vars.score = math.floor(self.score)
	vars.misses = math.floor(self.misses)
	vars.accuracy = math.truncate(self.accuracy * 100, 2)
	vars.rating = ratingStr

	self.scoreText.content = self.scoreFormat:gsub("%%(%w+)", vars)
	self.scoreText:screenCenter("x")

	if rating then self:popUpScore(rating) end
end

function PlayState:tryPause()
	local event = self.scripts:call("paused")
	if event ~= Script.Event_Cancel then
		game.camera:unfollow()
		game.camera:freeze()
		self.camNotes:freeze()
		self.camHUD:freeze()

		game.sound.music:pause()
		if self.vocals then self.vocals:pause() end
		if self.dadVocals then self.dadVocals:pause() end

		self.paused = true

		if self.buttons then
			self.buttons:disable()
		end

		local pause = PauseSubstate()
		pause.cameras = {self.camOther}

		self:openSubstate(pause)
	end
end

function PlayState:tryGameOver()
	local event = self.scripts:event("onGameOver", Events.GameOver())
	if not event.cancelled then
		self.paused = event.pauseGame

		if event.pauseSong then
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			if self.dadVocals then self.dadVocals:pause() end
		end

		self.camNotes.visible = false
		self.camHUD.visible = false
		self.boyfriend.visible = false

		if self.buttons then
			self.buttons:disable()
		end

		GameOverSubstate.characterName = event.characterName
		GameOverSubstate.deathSoundName = event.deathSoundName
		GameOverSubstate.loopSoundName = event.loopSoundName
		GameOverSubstate.endSoundName = event.endSoundName
		GameOverSubstate.deaths = GameOverSubstate.deaths + 1

		self.scripts:call("gameOverCreate")

		self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x, self.stage.boyfriendPos.y))
		self.isDead = true

		self.scripts:call("postGameOverCreate")
	end
end

function PlayState.notefieldPress(notefield, time, key)
	local hit = notefield:press(time, key, false)
	if hit then
		if notefield.hitsound and notefield.hitsoundVolume > 0 then
			game.sound.play(notefield.hitsound, notefield.hitsoundVolume)
		end
	else
		local receptor = notefield.receptors[key + 1]
		if receptor then receptor:play("pressed", true) end
	end
	return hit
end

function PlayState:getKeyFromEvent(controls)
	for _, control in pairs(controls) do
		if PlayState.controlDirs[control] then
			return PlayState.controlDirs[control]
		end
	end
	return -1
end

function PlayState:onKeyPress(key, type, scancode, isrepeat, time)
	if self.substate and not self.persistentUpdate then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)

	if key < 0 then return end
	self.keysPressed[key] = true

	time = PlayState.conductor.time / 1000 + (time - self.lastTick) * game.sound.music:getActualPitch()
	for _, n in ipairs(self.notefields) do
		if not n.bot then PlayState.notefieldPress(n, time, key) end
	end
end

function PlayState:onKeyRelease(key, type, scancode, time)
	if self.substate and not self.persistentUpdate then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)

	if key < 0 then return end
	self.keysPressed[key] = false

	time = PlayState.conductor.time / 1000 + (time - self.lastTick) * game.sound.music:getActualPitch()
	for _, n in ipairs(self.notefields) do
		if not n.bot then n:release(time, key, true) end
	end
end

function PlayState:closeSubstate()
	PlayState.super.closeSubstate(self)

	game.camera:unfreeze()
	self.camNotes:unfreeze()
	self.camHUD:unfreeze()

	game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)

	if not self.startingSong then
		game.sound.music:play()
		local time = game.sound.music:tell()

		if self.vocals then
			self.vocals:seek(time)
			self.vocals:play()
		end
		if self.dadVocals then
			self.dadVocals:seek(time)
			self.dadVocals:play()
		end

		PlayState.conductor.time = time * 1000

		if Discord then self:updateDiscordRPC() end
	end

	if self.buttons then
		self.buttons:enable()
	end
end

function PlayState:endSong(skip)
	if skip == nil then skip = false end
	PlayState.seenCutscene = false
	self.startedCountdown = false

	if self.storyMode and not PlayState.seenCutscene and not skip then
		PlayState.seenCutscene = true

		local songName = paths.formatToSongPath(PlayState.SONG.song)
		local cutscenePaths = {
			paths.getMods('data/cutscenes/' .. songName .. '-end.lua'),
			paths.getMods('data/cutscenes/' .. songName .. '-end.json'),
			paths.getPath('data/cutscenes/' .. songName .. '-end.lua'),
			paths.getPath('data/cutscenes/' .. songName .. '-end.json')
		}

		local fileExist, cutsceneType
		for i, path in ipairs(cutscenePaths) do
			if paths.exists(path, 'file') then
				fileExist = true
				switch(path:ext(), {
					["lua"] = function() cutsceneType = "script" end,
					["json"] = function() cutsceneType = "data" end,
				})
			end
		end
		if fileExist then
			switch(cutsceneType, {
				["script"] = function()
					local cutsceneScript = Script('data/cutscenes/' .. songName .. '-end')
					cutsceneScript:call("create")
					self.scripts:add(cutsceneScript)
					cutsceneScript:call("postCreate")
				end,
				["data"] = function()
					local cutsceneData = paths.getJSON('data/cutscenes/' .. songName .. '-end')
					for i, event in ipairs(cutsceneData.cutscene) do
						self.timer:after(event.time / 1000, function()
							self:executeCutsceneEvent(event.event, true)
						end)
					end
				end
			})
			return
		else
			self:endSong(true)
			return
		end
	end

	local event = self.scripts:call("endSong")
	if event == Script.Event_Cancel then return end
	game.sound.music.onComplete = nil

	local formatSong = paths.formatToSongPath(self.SONG.song)
	Highscore.saveScore(formatSong, self.score, self.songDifficulty)

	if self.chartingMode then
		game.switchState(ChartingState())
		return
	end

	game.sound.music:reset(true)
	if self.vocals then self.vocals:stop() end
	if self.dadVocals then self.dadVocals:stop() end
	if self.storyMode then
		PlayState.storyScore = PlayState.storyScore + self.score

		table.remove(PlayState.storyPlaylist, 1)

		if #PlayState.storyPlaylist > 0 then
			PlayState.prevCamFollow = {
				x = game.camera.target.x,
				y = game.camera.target.y
			}
			game.sound.music:stop()

			if Discord then
				local detailsText = "Freeplay"
				if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

				Discord.changePresence({
					details = detailsText,
					state = 'Loading next song..'
				})
			end

			PlayState.loadSong(PlayState.storyPlaylist[1], PlayState.songDifficulty)
			game.resetState(true)
		else
			Highscore.saveWeekScore(self.storyWeekFile, self.storyScore, self.songDifficulty)
			game.switchState(StoryMenuState())
			GameOverSubstate.deaths = 0

			util.playMenuMusic()
		end
	else
		game.camera:unfollow()
		game.switchState(FreeplayState())
		GameOverSubstate.deaths = 0

		util.playMenuMusic()
	end

	self.scripts:call("postEndSong")
end

function PlayState:updateDiscordRPC(paused)
	if not Discord then return end

	local detailsText = "Freeplay"
	if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

	local diff = PlayState.defaultDifficulty
	if PlayState.songDifficulty ~= "" then
		diff = PlayState.songDifficulty:gsub("^%l", string.upper)
	end

	if paused then
		Discord.changePresence({
			details = "Paused - " .. detailsText,
			state = PlayState.getSongName() .. ' - [' .. diff .. ']'
		})
		return
	end

	if self.startingSong or not game.sound.music or not game.sound.music:isPlaying() then
		Discord.changePresence({
			details = detailsText,
			state = PlayState.getSongName() .. ' - [' .. diff .. ']'
		})
	else
		local startTimestamp = os.time(os.date("*t"))
		local endTimestamp = (startTimestamp + game.sound.music:getDuration()) - PlayState.conductor.time / 1000
		Discord.changePresence({
			details = detailsText,
			state = PlayState.getSongName() .. ' - [' .. diff .. ']',
			startTimestamp = math.floor(startTimestamp),
			endTimestamp = math.floor(endTimestamp)
		})
	end
end

function PlayState:leave()
	self.scripts:call("leave")

	PlayState.conductor = nil
	Timer.setSpeed(1)

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	for _, notefield in ipairs(self.notefields) do notefield:destroy() end

	self.scripts:call("postLeave")
	self.scripts:close()
end

return PlayState
