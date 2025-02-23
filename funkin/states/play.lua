local Events = require "funkin.backend.scripting.events"
local PauseSubstate = require "funkin.substates.pause"

---@class PlayState:State
local PlayState = State:extend("PlayState")
PlayState.defaultDifficulty = "normal"

PlayState.inputDirections = {
	note_left = 0,
	note_down = 1,
	note_up = 2,
	note_right = 3
}
PlayState.keysControls = {}
for control, key in pairs(PlayState.inputDirections) do
	PlayState.keysControls[key] = control
end

PlayState.SONG = nil
PlayState.songDifficulty = ""

PlayState.storyPlaylist = {}
PlayState.storyMode = false
PlayState.storyWeek = ""
PlayState.storyScore = 0
PlayState.storyWeekFile = ""

PlayState.seenCutscene = false
PlayState.canFadeInReceptors = true
PlayState.prevCamFollow = nil

-- Charting Stuff
PlayState.chartingMode = false
PlayState.startPos = 0

function PlayState.loadSong(song, diff)
	diff = diff or PlayState.defaultDifficulty
	PlayState.songDifficulty = diff

	PlayState.SONG = Parser.getChart(song, diff)

	return true
end

function PlayState.getCutscene(isEnd)
	local name = paths.formatToSongPath(PlayState.SONG.song)
	if isEnd then name = name .. "-end" end

	for _, path in ipairs({
		paths.getMods("data/cutscenes/" .. name .. ".lua"),
		paths.getMods("data/cutscenes/" .. name .. ".json"),
		paths.getPath("data/cutscenes/" .. name .. ".lua"),
		paths.getPath("data/cutscenes/" .. name .. ".json")
	}) do
		if paths.exists(path, "file") then
			return name, path:ext() == "lua" and 1 or 2
		end
	end
end

function PlayState:new(storyMode, song, diff)
	PlayState.super.new(self)

	if storyMode ~= nil then
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
	if PlayState.SONG == nil then PlayState.loadSong("test") end
	PlayState.SONG.skin = util.getSongSkin(PlayState.SONG)

	local songName = paths.formatToSongPath(PlayState.SONG.song)

	local conductor = Conductor():setSong(PlayState.SONG)
	conductor.time = self.startPos - conductor.crotchet * 5
	conductor.onStep = bind(self, self.step)
	conductor.onBeat = bind(self, self.beat)
	conductor.onSection = bind(self, self.section)
	PlayState.conductor = conductor

	self.skipConductor = false

	Note.defaultSustainSegments = 3
	NoteModifier.reset()

	self.timer = TimerManager()
	self.tween = Tween()
	self.camPosTween = nil

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts", "data/scripts/" .. songName, "songs/" .. songName)

	self.events = table.clone(PlayState.SONG.events)
	self.eventScripts = {}
	for _, e in ipairs(self.events) do
		local scriptPath = "data/events/" .. e.e:gsub(" ", "-"):lower()
		if not self.eventScripts[e.e] then
			self.eventScripts[e.e] = Script(scriptPath)
			self.eventScripts[e.e].belongsTo = e.e
			self.scripts:add(self.eventScripts[e.e])
		end
	end

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
	self.timer.timeScale = 1
	self.tween.timeScale = 1

	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	self.scripts:call("create")

	self.camNotes = Camera() --Camera will be changed to ActorCamera once that class is done
	self.camHUD = Camera()
	self.camOther = Camera()
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camNotes, false)
	game.cameras.add(self.camOther, false)

	self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100

	local difficulty = PlayState.songDifficulty:lower()
	if game.sound.music then game.sound.music:reset(true) end
	game.sound.loadMusic(paths.getInst(songName, difficulty, true)
		or paths.getInst(songName, nil, true))
	game.sound.music:setLooping(false)
	game.sound.music:setVolume(ClientPrefs.data.musicVolume / 100)
	game.sound.music.onComplete = function() self:endSong() end

	self.stage = Stage(PlayState.SONG.stage)
	self:add(self.stage)
	self.scripts:add(self.stage.script)

	local char = PlayState.SONG.gfVersion
	if char and char ~= "" then
		self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
			char, false)
		self.gf:setScrollFactor(0.95, 0.95)
		self:add(self.gf)
		self.scripts:add(self.gf.script)
	end
	char = PlayState.SONG.player2
	if char and char ~= "" then
		self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y,
			char, false)
		self:add(self.dad)
		self.scripts:add(self.dad.script)
	end
	char = PlayState.SONG.player1
	if char and char ~= "" then
		self.boyfriend = Character(self.stage.boyfriendPos.x, self.stage.boyfriendPos.y,
			char, true)
		self:add(self.boyfriend)
		self.scripts:add(self.boyfriend.script)
	end

	if self.gf and self.dad and self.dad.char:startsWith("gf") then
		self.gf.visible = false
		self.dad:setPosition(self.gf.x, self.gf.y)
	end

	self:add(self.stage.foreground)

	self.judgeSprites = Judgements(game.width / 3, 264, PlayState.SONG.skin)
	self:add(self.judgeSprites)

	game.camera.zoom, self.camZoom, self.camZooming,
	self.camZoomSpeed, self.camSpeed, self.camTarget =
		self.stage.camZoom, self.stage.camZoom, false,
		self.stage.camZoomSpeed, self.stage.camSpeed
	if PlayState.prevCamFollow then
		self.camFollow = PlayState.prevCamFollow
		PlayState.prevCamFollow = nil
	else
		self.camFollow = {
			x = 0,
			y = 0,
			tweening = false,
			set = function(this, x, y)
				this.x = x
				this.y = y
			end
		}
	end

	local p1, p2 = PlayState.SONG.player1, PlayState.SONG.player2
	local playerVocals, enemyVocals, volume =
		(p1 and paths.getVoices(songName, p1 .. "-" .. difficulty, true))
		or paths.getVoices(songName, "Player-" .. difficulty, true)
		or paths.getVoices(songName, difficulty, true)
		or (p1 and paths.getVoices(songName, p1, true))
		or paths.getVoices(songName, "Player", true)
		or paths.getVoices(songName, nil, true),
		(p2 and paths.getVoices(songName, p2 .. "-" .. difficulty, true))
		or paths.getVoices(songName, "Opponent-" .. difficulty, true)
		or (p2 and paths.getVoices(songName, PlayState.SONG.player2, true))
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
	local y, keys, volume = game.height / 2, 4, ClientPrefs.data.vocalVolume / 100
	self.playerNotefield = Notefield(0, y, keys, PlayState.SONG.skin,
		self.boyfriend, playerVocals, PlayState.SONG.speed)
	self.enemyNotefield = Notefield(0, y, keys, PlayState.SONG.skin,
		self.dad, enemyVocals, PlayState.SONG.speed)
	self.playerNotefield.bot, self.enemyNotefield.bot,
	self.enemyNotefield.canSpawnSplash = ClientPrefs.data.botplayMode, true, false
	self.playerNotefield.cameras, self.enemyNotefield.cameras = {self.camNotes}, {self.camNotes}
	self.notefields = {self.playerNotefield, self.enemyNotefield, {character = self.gf}}
	self:positionNotefields()
	self.enemyNotefield:makeNotesFromChart(PlayState.SONG.notes.enemy)
	self.playerNotefield:makeNotesFromChart(PlayState.SONG.notes.player)
	self:add(self.enemyNotefield)
	self:add(self.playerNotefield)

	if PlayState.canFadeInReceptors then
		for _, notefield in ipairs(self.notefields) do
			if notefield.is then
				for _, receptor in ipairs(notefield.receptors) do
					receptor.alpha = 0
				end
			end
		end
	end

	local notefield
	for i, event in ipairs(self.events) do
		if event.t > 10 then
			break
		elseif event.e == "FocusCamera" then
			self:executeEvent(event)
			table.remove(self.events, i)
			break
		end
	end

	self.countdown = Countdown()
	self.countdown:screenCenter()
	self:add(self.countdown)

	local isPixel = PlayState.SONG.skin:endsWith("-pixel")
	local event = self.scripts:event("onCountdownCreation",
		Events.CountdownCreation({}, isPixel and {x = 7, y = 7} or {x = 1, y = 1}, not isPixel))
	if not event.cancelled then
		self.countdown.data = #event.data == 0 and {
			{
				sound = util.getSkinPath(PlayState.SONG.skin, "intro3", "sound"),
			},
			{
				sound = util.getSkinPath(PlayState.SONG.skin, "intro2", "sound"),
				image = util.getSkinPath(PlayState.SONG.skin, "ready", "image")
			},
			{
				sound = util.getSkinPath(PlayState.SONG.skin, "intro1", "sound"),
				image = util.getSkinPath(PlayState.SONG.skin, "set", "image")
			},
			{
				sound = util.getSkinPath(PlayState.SONG.skin, "introGo", "sound"),
				image = util.getSkinPath(PlayState.SONG.skin, "go", "image")
			}
		} or event.data
		self.countdown.scale = event.scale
		self.countdown.antialiasing = event.antialiasing
	end

	self.healthBar = HealthBar(self.boyfriend and self.boyfriend.icon or nil,
		self.dad and self.dad.icon or nil)
	self.healthBar:screenCenter("x").y = game.height * (self.downScroll and 0.1 or 0.9)
	self:add(self.healthBar)

	self.scoreText = Text(0, 0, "", paths.getFont("vcr.ttf", 16), Color.WHITE, "right")
	self.scoreText.outline.width = 1
	self.scoreText.antialiasing = false
	self:add(self.scoreText)

	for _, o in ipairs({
		self.judgeSprites, self.countdown, self.healthBar, self.scoreText
	}) do o.cameras = {self.camHUD} end

	self.score = 0
	self.combo = 0
	self.misses = 0
	self.health = 1

	self.ratings = {
		{name = "perfect", time = 0.0125, score = 400, splash = true,  mod = 1},
		{name = "sick",    time = 0.045,  score = 350, splash = true,  mod = 0.98},
		{name = "good",    time = 0.090,  score = 200, splash = false, mod = 0.7},
		{name = "bad",     time = 0.135,  score = 100, splash = false, mod = 0.4},
		{name = "shit",    time = -1,     score = 50,  splash = false, mod = 0.2}
	}
	for _, r in ipairs(self.ratings) do
		self[r.name .. "s"] = 0
	end

	if love.system.getDevice() == "Mobile" then
		local w, h = game.width / 4, game.height

		self.buttons = VirtualPadGroup()

		local left = VirtualPad("left", 0, 0, w, h, Color.PURPLE)
		local down = VirtualPad("down", w, 0, w, h, Color.BLUE)
		local up = VirtualPad("up", w * 2, 0, w, h, Color.LIME)
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
	end

	if self.buttons then self.buttons:disable() end

	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = bind(self, self.onKeyPress)
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = bind(self, self.onKeyRelease)
	controls:bindRelease(self.bindedKeyRelease)

	if self.downScroll then
		for _, notefield in ipairs(self.notefields) do
			if notefield.is then notefield.downscroll = true end
		end
	end
	self:positionText()

	if PlayState.storyMode and not PlayState.seenCutscene then
		local name, type = PlayState.getCutscene()
		if name then
			self:executeCutscene(name, type, function(event)
				local skipCountdown = event and event.params[1] or false
				if skipCountdown then
					self:startSong(0)
					if self.buttons then self:add(self.buttons) end
					for _, notefield in ipairs(self.notefields) do
						if notefield.is and PlayState.canFadeInReceptors then
							notefield:fadeInReceptors()
						end
					end
					PlayState.canFadeInReceptors = false
				else
					self:startCountdown()
				end
			end)
		else
			self:startCountdown()
		end
	else
		self:startCountdown()
	end
	self:recalculateRating()

	-- PRELOAD STUFF TO GET RID OF THE FATASS LAGS!!
	local path = "skins/" .. PlayState.SONG.skin .. "/"
	for _, r in ipairs(self.ratings) do paths.getImage(path .. r.name) end
	for _, num in ipairs({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "negative"}) do
		paths.getImage(path .. "num" .. num)
	end
	local sprite
	for i, part in pairs(paths.getSkin(PlayState.SONG.skin)) do
		sprite = part.sprite
		if sprite then paths.getImage(path .. sprite) end
	end
	if ClientPrefs.data.hitSound > 0 then paths.getSound("hitsound") end

	PlayState.super.enter(self)
	collectgarbage()

	self.scripts:call("postCreate")

	game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
	game.camera:snapToTarget()
end

function PlayState:executeCutscene(name, type, onComplete)
	PlayState.seenCutscene = true
	if type == 1 then
		local cutsceneScript = Script("data/cutscenes/" .. name)
		cutsceneScript.errorCallback:add(function()
			print("Cutscene returned a error. Skipping")
			cutsceneScript:close()
		end)
		cutsceneScript.closeCallback:add(function()
			if onComplete then onComplete() end
			onComplete = nil
		end)

		cutsceneScript:call("create")
		if isEnd then cutsceneScript:call("postCreate") end

		self.scripts:add(cutsceneScript)
	else
		local s, data = pcall(paths.getJSON, "data/cutscenes/" .. name)
		if not s then
			print("JSON cutscene returned a error. Skipping;", data)
			if onComplete then onComplete() end
			return
		end

		for _, e in ipairs(data.cutscene) do
			Timer():start(e.time / 1000, function()
				self:executeCutsceneEvent(e.event, onComplete)
			end)
		end
	end
end

function PlayState:executeCutsceneEvent(event, onComplete)
	switch(event.name, {
		['Camera Position'] = function()
			local xCam, yCam = event.params[1], event.params[2]
			local isTweening = event.params[3]
			local time = event.params[4]
			local ease = event.params[5]
			if isTweening then
				game.camera:follow(self.camFollow, nil)
				Tween.tween(self.camFollow, {x = xCam, y = yCam}, time, {ease = Ease[ease]})
			else
				self.state.camFollow:set(xCam, yCam)
				game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
			end
		end,
		['Camera Zoom'] = function()
			local zoomCam = event.params[1]
			local isTweening = event.params[2]
			local time = event.params[3]
			local ease = event.params[4]
			if isTweening then
				Tween.tween(game.camera, {zoom = zoomCam}, time, {ease = Ease[ease]})
			else
				game.camera.zoom = zoomCam
			end
		end,
		["Play Sound"] = function()
			local soundPath = event.params[1]
			local volume = event.params[2]
			local isFading = event.params[3]
			local time = event.params[4]
			local volStart, volEnd = event.params[5], event.params[6]

			local sound = util.playSfx(paths.getSound(soundPath), volume)
			if isFading then sound:fade(time, volStart, volEnd) end
		end,
		["Play Animation"] = function()
			local character, nf, anim = nil, self.notefields, event.params[2]
			switch(event.params[1], {
				[{"bf", "boyfriend", "player"}] = function() character = nf[1].character end,
				[{"gf", "girlfriend", "bystander"}] = function() character = nf[3].character end,
				[{"dad", "enemy", "opponent"}] = function() character = nf[2].character end
			})
			if character then character:playAnim(anim, true) end
		end,
		["End Cutscene"] = function()
			game.camera:follow(self.state.camFollow, nil, 2.4 * self.camSpeed)
			if onComplete then onComplete(event) end
		end
	})
end

function PlayState:positionNotefields()
	if self.middleScroll then
		self.playerNotefield:screenCenter("x")

		for _, notefield in ipairs(self.notefields) do
			if notefield.is and notefield ~= self.playerNotefield then
				notefield.visible = false
			end
		end
	else
		local baseX = 44
		self.playerNotefield.x = game.width / 2 + baseX
		self.enemyNotefield.x = baseX

		for _, notefield in ipairs(self.notefields) do
			if notefield.is then notefield.visible = true end
		end
	end
end

function PlayState:positionText()
	self.scoreText.x, self.scoreText.y = self.healthBar.x + self.healthBar.bg.width - 190, self.healthBar.y + 30
end

function PlayState:getRating(a, b)
	local diff = math.abs(a - b)
	for _, r in ipairs(self.ratings) do
		if diff <= (r.time < 0 and Note.safeZoneOffset or r.time) then return r end
	end
end

function PlayState:startCountdown()
	if self.buttons then self:add(self.buttons) end

	local event = self.scripts:call("startCountdown")
	if event == Script.Event_Cancel then return end

	self:setPlayback(ClientPrefs.data.playback)

	if not PlayState.conductor then return end
	self.doCountdownAtBeats = PlayState.startPos / PlayState.conductor.crotchet - 4
	self.startedCountdown = true
	self.countdown.duration = PlayState.conductor.crotchet / 1000
	self.countdown.playback = 1

	for _, notefield in ipairs(self.notefields) do
		if notefield.is and PlayState.canFadeInReceptors then
			notefield:fadeInReceptors()
		end
	end
	PlayState.canFadeInReceptors = false
end

function PlayState:setPlayback(playback)
	playback = playback or self.playback
	game.sound.music:setPitch(playback)

	local lastVocals
	for _, notefield in ipairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals:setPitch(playback)
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil

	self.playback = playback
	self.timer.timeScale = playback
	self.tween.timeScale = playback
end

function PlayState:playSong(daTime)
	self:setPlayback(self.playback)

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

function PlayState:pauseSong()
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

function PlayState:resyncSong()
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

function PlayState:getCameraPosition(char)
	local camX, camY = char:getMidpoint()
	if char == self.gf then
		camX, camY = camX - char.cameraPosition.x + self.stage.gfCam.x,
			camY - char.cameraPosition.y + self.stage.gfCam.y
	elseif char.isPlayer then
		camX, camY = camX - 100 - char.cameraPosition.x + self.stage.boyfriendCam.x,
			camY - 100 + char.cameraPosition.y + self.stage.boyfriendCam.y
	else
		camX, camY = camX + 150 + char.cameraPosition.x + self.stage.dadCam.x,
			camY - 100 + char.cameraPosition.y + self.stage.dadCam.y
	end
	return camX, camY
end

function PlayState:cameraMovement(ox, oy, easing, time)
	local event = self.scripts:event("onCameraMove", Events.CameraMove(self.camTarget))
	local camX, camY = (ox or 0) + event.offset.x, (oy or 0) + event.offset.y
	if self.camPosTween then
		self.camPosTween:cancel()
	end
	if easing then
		if game.camera.followLerp then
			game.camera:follow(self.camFollow, nil)
		end
		self.camPosTween = self.tween:tween(self.camFollow, {x = camX, y = camY}, time, {
			ease = Ease[easing],
			onComplete = function()
				self.camFollow.tweening = false
			end
		})
	else
		if not game.camera.followLerp then
			game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
		end
		self.camPosTween = nil
		self.camFollow:set(camX, camY)
	end
end

function PlayState:step(s)
	if self.skipConductor then return end

	if not self.startingSong then
		self:resyncSong()

		if Discord then
			coroutine.wrap(PlayState.updateDiscordRPC)(self)
		end
	end

	self.scripts:set("curStep", s)
	self.scripts:call("step", s)
	self.scripts:call("postStep", s)
end

function PlayState:beat(b)
	if self.skipConductor then return end

	self.scripts:set("curBeat", b)
	self.scripts:call("beat", b)

	local character
	for _, notefield in ipairs(self.notefields) do
		character = notefield.character
		if character then character:beat(b) end
	end

	local val, healthBar = 1.2, self.healthBar
	healthBar.iconScale = val
	if healthBar.iconP1 then
		healthBar.iconP1:setScale(val)
	end
	if healthBar.iconP2 then
		healthBar.iconP2:setScale(val)
	end

	self.scripts:call("postBeat", b)
end

function PlayState:section(s)
	if self.skipConductor then return end

	self.scripts:set("curSection", s)
	self.scripts:call("section", s)

	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	if self.camZooming and game.camera.zoom < 1.35 then
		game.camera.zoom = game.camera.zoom + 0.015
		self.camHUD.zoom = self.camHUD.zoom + 0.03
	end

	self.scripts:call("postSection", s)
end

function PlayState:focus(f)
	self.scripts:call("focus", f)
	if Discord and love.autoPause then self:updateDiscordRPC(not f) end
	self.scripts:call("postFocus", f)
end

function PlayState:executeEvent(event)
	for _, s in pairs(self.eventScripts) do
		if s.belongsTo == event.e then s:call("event", event) end
	end
	self.scripts:call("onEvent", event)
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

function PlayState:resetStroke(notefield, dir, doPress)
	local receptor = notefield.receptors[dir + 1]
	if receptor then
		receptor:play((doPress and not notefield.bot)
			and "pressed" or "static")
	end
end

function PlayState:update(dt)
	self.timer:update(dt)
	self.tween:update(dt)

	if self.cutscene then self.cutscene:update(dt) end

	dt = dt * self.playback
	self.lastTick = love.timer.getTime()

	if self.startedCountdown then
		PlayState.conductor.time = PlayState.conductor.time + dt * 1000

		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false
			self.camZooming = true

			self:playSong(self.startPos)
			self:section(0)
			self.scripts:call("songStart")
		else
			local noFocus, events, e = true, self.events
			while events[1] do
				e = events[1]
				if e.t <= PlayState.conductor.time then
					self:executeEvent(e)
					table.remove(events, 1)
					if e.e == "FocusCamera" then noFocus = false end
				else
					break
				end
			end
			if noFocus and self.camTarget and game.camera.followLerp then
				self:cameraMovement(self:getCameraPosition(self.camTarget))
			end
		end

		PlayState.conductor:update()
		if self.skipConductor then self.skipConductor = false end

		if self.startingSong and self.doCountdownAtBeats then
			self:doCountdown(math.floor(
				PlayState.conductor.currentBeatFloat - self.doCountdownAtBeats + 1
			))
		end
	end

	local time = PlayState.conductor.time / 1000
	local missOffset = time - Note.safeZoneOffset / 1.25
	for _, notefield in ipairs(self.notefields) do
		if notefield.character then
			notefield.character.waitReleaseAfterSing = not notefield.bot
		end
		if notefield.is then
			notefield.time, notefield.beat = time, PlayState.conductor.currentBeatFloat

			local isPlayer, sustainHitOffset, noSustainHit, sustainTime,
			noteTime, lastPress, dir, fullyHeldSustain, char, hasInput, resetVolume =
				not notefield.bot, 0.25 / notefield.speed
			for _, note in ipairs(notefield:getNotes(time, nil, true)) do
				noteTime, lastPress, dir, noSustainHit, char =
					note.time, note.lastPress, note.direction,
					not note.wasGoodSustainHit, note.character or notefield.character
				hasInput = not isPlayer or controls:down(PlayState.keysControls[dir])

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
						end
					end

					if noSustainHit and hasInput and char then
						char.lastHit = PlayState.conductor.time
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

	self.scripts:call("update", dt)
	PlayState.super.update(self, dt)

	if self.camZooming then
		game.camera.zoom = util.coolLerp(game.camera.zoom, self.camZoom, 3, dt * self.camZoomSpeed)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt * self.camZoomSpeed)
	end
	self.camNotes.zoom = self.camHUD.zoom

	if self.startedCountdown and controls:pressed("pause") then
		self:tryPause()
	end

	self.healthBar.value = util.coolLerp(self.healthBar.value, self.health, 15, dt)
	if not self.isDead and self.health <= 0 then self:tryGameOver() end

	if self.startedCountdown then
		if controls:pressed("debug_1") then
			game.camera:unfollow()
			self:pauseSong()
			game.switchState(ChartingState())
		end

		if controls:pressed("debug_2") then
			game.camera:unfollow()
			game.sound.music:pause()
			self:pauseSong()
			CharacterEditor.onPlayState = true
			game.switchState(CharacterEditor())
		end

		if not self.isDead and controls:pressed("reset") then self:tryGameOver() end
	end

	if Project.DEBUG_MODE then
		if game.keys.justPressed.ONE then self.playerNotefield.bot = not self.playerNotefield.bot end
		if game.keys.justPressed.TWO then self:endSong() end
		if game.keys.justPressed.THREE then
			local time, vocals = (PlayState.conductor.time +
				PlayState.conductor.crotchet * (game.keys.pressed.SHIFT and 8 or 4)) / 1000
			self.skipConductor, PlayState.conductor.time = true, time * 1000
			game.sound.music:seek(time)
			for _, notefield in ipairs(self.notefields) do
				vocals = notefield.vocals
				if vocals then vocals:seek(time) end
			end
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
				for _, notefield in ipairs(self.notefields) do
					if notefield.is then notefield.downscroll = downscroll end
				end

				self.healthBar.y = game.height * (downscroll and 0.1 or 0.9)
				self:positionText()
				self.downScroll = downscroll
			end,
			["middleScroll"] = function()
				self.middleScroll = ClientPrefs.data.middleScroll
				self:positionNotefields()
			end,
			["botplayMode"] = function()
				self.playerNotefield.bot = ClientPrefs.data.botplayMode
				self:recalculateRating()
				self.usedBotplay = true
			end,
			["backgroundDim"] = function()
				self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100
			end,
			["playback"] = function()
				self:setPlayback(ClientPrefs.data.playback)
			end
		})

		game.sound.music:setVolume(ClientPrefs.data.musicVolume / 100)
		local volume, vocals = ClientPrefs.data.vocalVolume / 100
		for _, notefield in ipairs(self.notefields) do
			vocals = notefield.vocals
			if vocals then vocals:setVolume(volume) end
		end
	elseif category == "controls" then
		controls:unbindPress(self.bindedKeyPress)
		controls:unbindRelease(self.bindedKeyRelease)

		self.bindedKeyPress = bind(self, self.onKeyPress)
		controls:bindPress(self.bindedKeyPress)

		self.bindedKeyRelease = bind(self, self.onKeyRelease)
		controls:bindRelease(self.bindedKeyRelease)
	end

	self.scripts:call("onSettingChange", category, setting)
end

function PlayState:goodNoteHit(note, time)
	local rating = self:getRating(note.time, time)

	self.scripts:call("goodNoteHit", note, rating)

	local notefield, dir, isSustain =
		note.parent, note.direction, note.sustain
	local event = self.scripts:event("onNoteHit",
		Events.NoteHit(notefield, note,
			note.character or notefield.character, rating))
	if not event.cancelled and not note.wasGoodHit then
		note.wasGoodHit = true

		if event.unmuteVocals then
			local vocals = notefield.vocals or self.playerNotefield.vocals
			if vocals then vocals:setVolume(ClientPrefs.data.vocalVolume / 100) end
		end

		local char = event.character
		if char and not event.cancelledAnim then
			local lastSustain, type = notefield.lastSustain, note.type
			if type ~= "alt" then type = nil end
			if lastSustain and not isSustain
				and lastSustain.sustainTime > note.sustainTime then
				local dir = lastSustain.direction
				if char.dirAnim ~= dir then
					char:sing(dir, type, false)
				end
			else
				char:sing(dir, type)
			end
		end

		notefield.lastSustain = isSustain and note or nil
		if not isSustain then
			notefield:removeNote(note)
		elseif rating.mod < 0.5 then
			note:ghost()
		end

		local receptor = notefield.receptors[dir + 1]
		if receptor then
			if not event.strumGlowCancelled then
				local time = notefield.bot and receptor.holdTime
				receptor:play("confirm", true)
				if not note.sustain then receptor.holdTime = time ~= 0 and time or 0.25 end
				if ClientPrefs.data.noteSplash and notefield.canSpawnSplash and rating.splash then
					receptor:spawnSplash()
				end
			end
			if isSustain and not event.coverSpawnCancelled then
				receptor:spawnCover(note)
			end
		end

		if self.playerNotefield == notefield then
			self.health = math.min(self.health + 0.023, 2)
			self.score, self.combo = self.score + rating.score, math.max(self.combo, 0) + 1
			self:recalculateRating(rating.name)

			local hitSoundVolume = ClientPrefs.data.hitSound
			if hitSoundVolume > 0 then
				game.sound.play(paths.getSound("hitsound"), hitSoundVolume / 100)
			end
		end
	end

	self.scripts:call("postGoodNoteHit", note, rating)
end

function PlayState:goodSustainHit(note, time, fullyHeldSustain)
	self.scripts:call("goodSustainHit", note)

	local notefield, dir, fullScore =
		note.parent, note.direction, fullyHeldSustain ~= nil
	local event = self.scripts:event("onSustainHit",
		Events.NoteHit(notefield, note,
			note.character or notefield.character))
	if not event.cancelled and not note.wasGoodSustainHit then
		note.wasGoodSustainHit = true

		if notefield == self.playerNotefield then
			if fullScore then
				self.score = self.score + note.sustainTime * 1000
			else
				self.score = self.score
					+ math.min(time - note.lastPress + Note.safeZoneOffset,
						note.sustainTime) * 1000
			end
			self:recalculateRating()
		end

		if not event.cancelledAnim then
			self:resetStroke(notefield, dir, fullyHeldSustain)
		end
		if fullScore then notefield:removeNote(note) end
	end

	self.scripts:call("postGoodSustainHit", note)
end

-- dir can be nil for non-ghost-tap
function PlayState:miss(note, dir)
	local ghostMiss = dir ~= nil
	if not ghostMiss then dir = note.direction end

	local funcParam = ghostMiss and dir or note
	self.scripts:call(ghostMiss and "miss" or "noteMiss", funcParam)

	local notefield = ghostMiss and note or note.parent
	local event = self.scripts:event(ghostMiss and "onMiss" or "onNoteMiss",
		Events.Miss(notefield, dir, ghostMiss and nil or note,
			note.character or notefield.character))
	if not event.cancelled and (ghostMiss or not note.tooLate) then
		if not ghostMiss then
			note.tooLate = true
		end

		if event.muteVocals and notefield.vocals then notefield.vocals:setVolume(0) end

		if event.triggerSound then
			util.playSfx(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)),
				love.math.random(1, 2) / 10)
		end

		local char = event.character
		if char and not event.cancelledAnim then char:sing(dir, "miss") end

		if notefield == self.playerNotefield then
			if self.gf and not event.cancelledSadGF and self.combo >= 10
				and self.gf.__animations.sad then
				self.gf:playAnim("sad", true)
				self.gf.lastHit = notefield.time * 1000
			end

			self.health = math.max(self.health - (ghostMiss and 0.04 or 0.0475), 0)
			self.score, self.misses, self.combo =
				self.score - 100, self.misses + 1, math.min(self.combo, 0) - 1
			self:recalculateRating()
			self:popUpScore()
		end
	end

	self.scripts:call(ghostMiss and "postMiss" or "postNoteMiss", funcParam)
end

function PlayState:recalculateRating(rating)
	self.scoreText.content = ClientPrefs.data.botplayMode and "Botplay Enabled" or
		"Score: " .. util.formatNumber(math.floor(self.score))
	if rating then
		local field = rating .. "s"
		self[field] = (self[field] or 0) + 1
		self:popUpScore(rating)
	end
end

function PlayState:popUpScore(rating)
	local event = self.scripts:event('onPopUpScore', Events.PopUpScore())
	if not event.cancelled then
		self.judgeSprites.ratingVisible = not event.hideRating
		self.judgeSprites.comboNumVisible = not event.hideScore
		self.judgeSprites:spawn(rating, self.combo)
	end
end

function PlayState:tryPause()
	local event = self.scripts:call("pause")
	if event ~= Script.Event_Cancel then
		game.camera:unfollow(false)
		game.camera:freeze()
		self.camNotes:freeze()
		self.camHUD:freeze()

		self:pauseSong()

		if self.buttons then self:remove(self.buttons) end

		local pause = PauseSubstate()
		pause.cameras = {self.camOther}
		self:openSubstate(pause)
	end
end

function PlayState:tryGameOver()
	local event = self.scripts:event("onGameOver", Events.GameOver())
	if not event.cancelled then
		if event.pauseSong then
			self:pauseSong()
		end
		self.paused = event.pauseGame

		self.camHUD.visible, self.camNotes.visible = false, false
		self.boyfriend.visible = false

		if self.buttons then self:remove(self.buttons) end

		GameOverSubstate.characterName = event.characterName
		GameOverSubstate.deathSoundName = event.deathSoundName
		GameOverSubstate.loopSoundName = event.loopSoundName
		GameOverSubstate.endSoundName = event.endSoundName
		GameOverSubstate.deaths = GameOverSubstate.deaths + 1

		self.scripts:call("gameOverCreate")

		self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x,
			self.stage.boyfriendPos.y))
		self.isDead = true

		self.scripts:call("postGameOverCreate")
	end
end

function PlayState:getKeyFromEvent(controls)
	for _, control in pairs(controls) do
		local dir = PlayState.inputDirections[control]
		if dir ~= nil then return dir end
	end
	return -1
end

function PlayState:onKeyPress(key, type, scancode, isrepeat, time)
	if self.substate and not self.persistentUpdate then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)
	if key < 0 then return end

	local fixedKey, offset = key + 1,
		(time - self.lastTick) * game.sound.music:getActualPitch()
	for _, notefield in ipairs(self.notefields) do
		if notefield.character then
			notefield.character.waitReleaseAfterSing = not notefield.bot
		end
		if notefield.is and not notefield.bot then
			time = notefield.time + offset
			local hitNotes, hasSustain = notefield:getNotes(time, key)
			local l = #hitNotes

			if ClientPrefs.data.ghostTap and l > 0 then
				for i = #notefield.recentPresses, 1, -1 do
					if time - notefield.recentPresses[i] > 0.12 * self.playback then
						table.remove(notefield.recentPresses, i)
					end
				end

				for _ = 1, #notefield.recentPresses do
					self.health = self.health - 0.09
				end
			elseif ClientPrefs.data.ghostTap then
				table.insert(notefield.recentPresses, time)
			end

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

function PlayState:onKeyRelease(key, type, scancode, time)
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

function PlayState:closeSubstate()
	self.scripts:call("substateClosed")
	PlayState.super.closeSubstate(self)

	game.camera:unfreeze()
	self.camNotes:unfreeze()
	self.camHUD:unfreeze()

	game.camera.target = self.camFollow

	if not self.startingSong then
		self:playSong()
		if Discord then self:updateDiscordRPC() end
	end

	if self.buttons then self:add(self.buttons) end

	self.scripts:call("postSubstateClosed")
end

function PlayState:endSong(skip)
	if PlayState.storyMode and not skip then
		local name, type = PlayState.getCutscene(true)
		if name then
			self:executeCutscene(name, type, function()
				self:endSong(true)
			end)
			return
		end
	end
	PlayState.seenCutscene = false
	game.sound.music:reset(true)

	local event = self.scripts:call("endSong")
	if event == Script.Event_Cancel then return end

	if not self.usedBotPlay then
		Highscore.saveScore(PlayState.SONG.song, self.score, self.songDifficulty)
	end
	if self.chartingMode then
		game.switchState(ChartingState())
		return
	end

	if PlayState.storyMode then
		PlayState.canFadeInReceptors = false
		if not self.usedBotPlay then
			PlayState.storyScore = PlayState.storyScore + self.score
		end

		table.remove(PlayState.storyPlaylist, 1)
		if #PlayState.storyPlaylist > 0 then
			game.sound.music:stop()

			if Discord then
				local detailsText = "Freeplay"
				if PlayState.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

				Discord.changePresence({
					details = detailsText,
					state = 'Loading next song..'
				})
			end

			PlayState.loadSong(PlayState.storyPlaylist[1], PlayState.songDifficulty)
			game.resetState(true)
		else
			GameOverSubstate.deaths = 0
			PlayState.canFadeInReceptors = true
			if not self.usedBotPlay then
				Highscore.saveWeekScore(self.storyWeekFile, self.storyScore, self.songDifficulty)
			end

			local stickers = Stickers(nil, StoryMenuState())
			self:add(stickers)

			util.playMenuMusic()
		end
	else
		GameOverSubstate.deaths = 0
		PlayState.canFadeInReceptors = true
		game.camera:unfollow()

		local stickers = Stickers(nil, FreeplayState())
		self:add(stickers)

		util.playMenuMusic()
	end
	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)
	game.sound.music.onComplete = nil

	self.scripts:call("postEndSong")
end

function PlayState:updateDiscordRPC(paused)
	if not Discord then return end

	local detailsText = "Freeplay"
	if PlayState.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

	local diff = PlayState.defaultDifficulty
	if PlayState.songDifficulty ~= "" then
		diff = PlayState.songDifficulty:gsub("^%l", string.upper)
	end

	if paused then
		Discord.changePresence({
			details = "Paused - " .. detailsText,
			state = PlayState.SONG.song .. ' - [' .. diff .. ']'
		})
		return
	end

	if self.startingSong or not game.sound.music or not game.sound.music:isPlaying() then
		Discord.changePresence({
			details = detailsText,
			state = PlayState.SONG.song .. ' - [' .. diff .. ']'
		})
	else
		local startTimestamp = os.time(os.date("*t"))
		local endTimestamp = (startTimestamp + game.sound.music:getDuration()) - PlayState.conductor.time / 1000
		Discord.changePresence({
			details = detailsText,
			state = PlayState.SONG.song .. ' - [' .. diff .. ']',
			startTimestamp = math.floor(startTimestamp),
			endTimestamp = math.floor(endTimestamp)
		})
	end
end

function PlayState:leave()
	self.scripts:call("leave")

	PlayState.prevCamFollow = self.camFollow
	PlayState.conductor = nil

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	self.scripts:call("postLeave")
	self.scripts:close()
end

return PlayState
