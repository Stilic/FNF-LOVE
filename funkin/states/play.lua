local Events = require "funkin.backend.scripting.events"

---@class PlayState:State
local PlayState = State:extend("PlayState")
PlayState.defaultDifficulty = "normal"
PlayState.transIn = TransitionData(0.5)

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

function PlayState:preload()
	local skin = PlayState.SONG.skin or "default"
	if type(skin) == "string" then
		PlayState.SONG.skin = paths.getSkin(PlayState.SONG.skin or "default")
		skin = PlayState.SONG.skin
	end

	local function skinPath(type, name) return {type, skin:getPath(name, type)} end
	local song = paths.formatToSongPath(PlayState.SONG.song)
	local diff, async = PlayState.songDifficulty:lower(), paths.async

	local function getInst()
		return async.getInst(song, diff) or async.getInst(song, nil)
	end
	local function getVocals(suffix, fallback, skip)
		local vocal = async.getVoices(song, suffix .. "-" .. diff) or
			async.getVoices(song, diff) or async.getVoices(song, suffix) or
			(fallback and async.getVoices(song, fallback) or nil) or
			(not skip and async.getVoices(song, nil) or nil)
		return vocal
	end

	local p1, p2 = PlayState.SONG.player1, PlayState.SONG.player2
	local playerVocals, enemyVocals =
		getVocals(p1 or "Player", "Player"),
		getVocals(p2 or "Opponent", "Opponent", true)
	getInst()

	local list = {
		skinPath("image", "ready"), skinPath("image", "set"), skinPath("image", "go"),
		skinPath("sound", "intro3"), skinPath("sound", "intro2"), skinPath("sound", "intro1"),
		skinPath("sound", "introGo"), {"sound", "hitsound"}
	}

	local path, sprite = "skins/" .. PlayState.SONG.skin.skin .. "/"
	for i, part in pairs(PlayState.SONG.skin.data) do
		sprite = part.sprite
		if part.skin then path = "skins/" .. part.skin .. "/" end
		if sprite then
			table.insert(list, {"image", path .. sprite})
		end
	end

	for i, rating in ipairs({"perfect", "sick", "good", "bad", "shit"}) do
		table.insert(list, skinPath("image", rating))
	end
	for i = 0, 9 do
		table.insert(list, skinPath("image", "num" .. i))
	end
	table.insert(list, skinPath("image", "healthBar"))
	table.insert(list, skinPath("image", "numnegative"))

	for i = 1, 3 do table.insert(list, {"sound", "gameplay/missnote" .. i}) end

	self.stage = Stage(PlayState.SONG.stage)
	for _, char in pairs({PlayState.SONG.gfVersion, PlayState.SONG.player2, PlayState.SONG.player1}) do
		if char and char ~= "" then
			local data = Parser.getCharacter(char)
			if data then
				table.insert(list, {"image", data.sprite})
				if data.animations then
					for _, anim in pairs(data.animations) do
						local atlas = select(7, anim)
						if atlas then
							table.insert(list, {"image", atlas})
						end
					end
				end
				table.insert(list, {"image", "icons/" .. data.icon or "face"})
			end
		end
	end
	paths.async.loadBatch(list)
end

function PlayState:enter()
	if PlayState.SONG == nil then PlayState.loadSong("test") end

	local songName = paths.formatToSongPath(PlayState.SONG.song)

	if type(PlayState.SONG.skin) == "string" then
		PlayState.SONG.skin = paths.getSkin(PlayState.SONG.skin or "default")
	end
	local skin = PlayState.SONG.skin

	local difficulty = PlayState.songDifficulty:lower()
	if game.sound.music then game.sound.music:reset(true) end
	game.sound.loadMusic(paths.getInst(songName, difficulty, true)
		or paths.getInst(songName, nil, true))
	game.sound.music.looped = false
	game.sound.music.volume = ClientPrefs.data.musicVolume / 100
	game.sound.music.onComplete = bind(self, self.endSong)

	local conductor = Conductor(PlayState.SONG.timeChanges)
	conductor.time = self.startPos - conductor.crotchet * 5
	conductor.onStep:add(bind(self, self.step))
	conductor.onBeat:add(bind(self, self.beat))
	conductor.onMeasure:add(bind(self, self.measure))
	PlayState.conductor = conductor

	self.skipConductor = false

	Note.defaultSustainSegments = 3
	NoteModifier.reset()

	self.timer = TimerManager()
	self.tween = Tween()
	self.camPosTween = nil

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

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts", "data/scripts/" .. songName, "songs/" .. songName)
	conductor.onTimeChange:add(function()
		self.scripts:set("bpm", conductor.bpm)
		self.scripts:set("crotchet", conductor.crotchet)
		self.scripts:set("stepCrotchet", conductor.stepCrotchet)
	end)
	conductor.onTimeChange:dispatch()

	self.events = table.clone(PlayState.SONG.events)
	self.eventScripts = {}

	local error
	for _, e in ipairs(self.events) do
		local scriptPath = "data/events/" .. e.e:gsub(" ", "-"):lower()
		if paths.exists(paths.getPath(scriptPath .. ".lua"), "file") then
			if not self.eventScripts[e.e] then
				self.eventScripts[e.e] = Script(scriptPath)
				self.scripts:add(self.eventScripts[e.e])
			end
		else
			if not error then
				error = "Events not found: "
			end
			if not error:find(e.e) then
				error = error .. e.e .. "; "
			end
		end
	end
	if error then Toast.error(error:sub(1, -3)) end

	self.scripts:call("create")

	self.camNotes = Camera() --Camera will be changed to ActorCamera once that class is done
	self.camHUD = Camera()
	self.camOther = Camera()
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camNotes, false)
	game.cameras.add(self.camOther, false)

	self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100

	self.stage:load()
	self:add(self.stage)
	if self.stage.script then self.scripts:add(self.stage.script) end
	self:add(self.stage.foreground)

	self.boyfriend, self.dad, self.gf =
		self.stage.boyfriend, self.stage.dad, self.stage.gf

	if self.boyfriend then self.scripts:add(self.boyfriend.script) end
	if self.gf then self.scripts:add(self.gf.script) end
	if self.dad then self.scripts:add(self.dad.script) end

	self.judgeSprites = Judgements(game.width / 3, 264, PlayState.SONG.skin)
	self:add(self.judgeSprites)

	game.camera.zoom, self.camZoom,
	self.camZoomSpeed, self.camSpeed, self.camTarget =
		self.stage.camZoom, self.stage.camZoom,
		self.stage.camZoomSpeed, self.stage.camSpeed

	self.zoomRate = conductor.timeSignNum
	self.hudZoomIntensity = 0.015 * 2
	self.camZoomIntensity = 1.015
	self.camZoomMult = 1

	if PlayState.prevCamFollow then
		self.camFollow = PlayState.prevCamFollow
		PlayState.prevCamFollow = nil
	else
		self.camFollow = Point()
		self.camFollow.tweening = false
	end

	local volume = ClientPrefs.data.vocalVolume / 100
	-- local function loadVocal(...)
		-- for _, p in ipairs({...}) do
			-- local file = paths.getVoices(songName, p .. "-" .. difficulty, true) or
				-- paths.getVoices(songName, p ~= "" and p or nil, p ~= "")
			-- if file then
				-- local vocal = game.sound.load(file)
				-- vocal.volume = volume; vocal.looped = false
				-- return vocal
			-- end
		-- end
	-- end

	local function getVocals(char, fallback, n)
		local file = (paths.getVoices(songName, char .. "-" .. difficulty) or
			paths.getVoices(songName, difficulty) or paths.getVoices(songName, char)) or
			(fallback and paths.getVoices(songName, fallback) or nil) or
			(n and paths.getVoices(songName, nil, true))
		if file then
			local vocal = game.sound.load(file)
			vocal.volume, vocal.looped = volume, false
			return vocal
		end
	end

	local p1, p2 = PlayState.SONG.player1, PlayState.SONG.player2
	local playerVocals, enemyVocals =
		getVocals(p1 or "Player", "Player", true),
		getVocals(p2 or "Opponent", "Opponent")

	-- {field name, char, vocals, botplay, splash}
	self.notefields = {}
	local y, keys, speed = game.height / 2, 4, PlayState.SONG.speed
	local config = {
		{"player", self.boyfriend, playerVocals, ClientPrefs.data.botplayMode, true},
		{"enemy", self.dad, enemyVocals, true},
	}
	for _, nf in ipairs(config) do
		local field, notes = nf[1] .. "Notefield", PlayState.SONG.notes[nf[1]]
		self[field] = Notefield(0, y, keys, skin, nf[2], nf[3], speed)
		local notefield = self[field]
		notefield.bot = nf[4]
		notefield.canSpawnSplash = nf[5] or false
		notefield.cameras = {self.camNotes}
		self:add(notefield)
		if notes then notefield:makeNotesFromChart(notes) end
		table.insert(self.notefields, notefield)
	end
	self:positionNotefields()
	table.insert(self.notefields, 3, {character = self.gf})

	if PlayState.canFadeInReceptors then
		for _, notefield in pairs(self.notefields) do
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

	local isPixel = skin.isPixel
	local event = self.scripts:event("onCountdownCreation",
		Events.CountdownCreation({}, isPixel and {x = 7, y = 7} or {x = 1, y = 1}, not isPixel))
	if not event.cancelled then
		self.countdown.data = #event.data == 0 and {
			{
				sound = skin:getPath("intro3", "sound"),
			},
			{
				sound = skin:getPath("intro2", "sound"),
				image = skin:getPath("ready", "image")
			},
			{
				sound = skin:getPath("intro1", "sound"),
				image = skin:getPath("set", "image")
			},
			{
				sound = skin:getPath("introGo", "sound"),
				image = skin:getPath("go", "image")
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
		{name = "bad",     time = 0.135,  score = 100, splash = false, mod = 0.4, resetCombo = true},
		{name = "shit",    time = -1,     score = 50,  splash = false, mod = 0.2, resetCombo = true}
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
			config = {round = {0, 0}}
		})
		self.buttons.cameras = {self.camOther}
	end

	if self.buttons then self.buttons:disable() end

	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = bind(self, self.onKeyPress)
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = bind(self, self.onKeyRelease)
	controls:bindRelease(self.bindedKeyRelease)

	if self.downScroll then
		for _, notefield in pairs(self.notefields) do
			if notefield.is then notefield.downscroll = true end
		end
	end
	self:positionText()

	if self.buttons then self:add(self.buttons) end

	if PlayState.storyMode and not PlayState.seenCutscene then
		local name, type = PlayState.getCutscene()
		if name then
			self:executeCutscene(name, type, function(event)
				local skipCountdown = event and event.params[1] or false
				if skipCountdown then
					self:startSong(self.startPos)
					self:fadeReceptors()
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

	PlayState.super.enter(self)
	collectgarbage()

	self.scripts:call("postCreate")

	game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
	game.camera:snapToTarget()

	self:update(0)
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
		for _, notefield in pairs(self.notefields) do
			if notefield.is then
				notefield:screenCenter("x")
				notefield.visible = (notefield == self.playerNotefield)
			end
		end
	else
		local total = 0
		for _, notefield in ipairs(self.notefields) do
			if notefield.is then total = total + 1 end
		end
		local baseX = 44
		local width = game.width - baseX
		local spacing, pos, notefield = width / total - 1, 0

		for i = #self.notefields, 1, -1 do
			notefield = self.notefields[i]
			if notefield.is then
				notefield.visible = true
				notefield.x = baseX + (spacing * pos)
				pos = pos + 1
			end
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

	self:fadeReceptors()
end

function PlayState:fadeReceptors()
	for _, notefield in pairs(self.notefields) do
		if notefield.is and PlayState.canFadeInReceptors then
			notefield:fadeInReceptors()
		end
	end
	PlayState.canFadeInReceptors = false
end

function PlayState:setPlayback(playback)
	playback = playback or self.playback
	game.sound.music.pitch = playback

	local lastVocals
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals.pitch = playback
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

	if daTime then game.sound.music.time = daTime end
	game.sound.music:play()

	local time, lastVocals = game.sound.music.time
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals.time = time
			notefield.vocals:play()
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil
	PlayState.conductor:update(time * 1000)

	self.paused = false
end

function PlayState:pauseSong()
	game.sound.music:pause()
	local lastVocals
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals:pause()
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil

	self.paused = true
end

function PlayState:resyncSong()
	local time, rate = game.sound.music.time, math.max(self.playback, 1)
	if math.abs(time - self.conductor.time / 1000) > 0.015 * rate then
		PlayState.conductor:update(time * 1000)
	end
	local maxDelay, vocals, lastVocals = 0.009262 * rate
	for _, notefield in pairs(self.notefields) do
		vocals = notefield.vocals
		if vocals and lastVocals ~= vocals and vocals:isPlaying()
			and vocals.time > 0.8 and math.abs(time - vocals.time) > maxDelay then
			vocals:pause()
			vocals.time = time
			vocals:play()
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
		camX, camY = camX - char.cameraPosition.x + self.stage.boyfriendCam.x,
			camY + char.cameraPosition.y + self.stage.boyfriendCam.y
	else
		camX, camY = camX + char.cameraPosition.x + self.stage.dadCam.x,
			camY + char.cameraPosition.y + self.stage.dadCam.y
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
	for _, notefield in pairs(self.notefields) do
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

	if --[[ClientPrefs.data.zoomCamera and]] game.camera.zoom < 1.35 and
		self.zoomRate > 0 and self.conductor.currentBeat % self.zoomRate == 0 then
		self.camZoomMult = self.camZoomIntensity
		self.camHUD.zoom = 1 + self.hudZoomIntensity
	end

	self.scripts:call("postBeat", b)
end

function PlayState:measure(m)
	if self.skipConductor then return end

	self.scripts:set("curMeasure", m)
	self.scripts:call("measure", m)

	self.scripts:call("postMeasure", m)
end

function PlayState:focus(f)
	self.scripts:call("focus", f)
	if Discord and love.autoPause then self:updateDiscordRPC(not f) end
	self.scripts:call("postFocus", f)
end

function PlayState:executeEvent(event)
	if self.eventScripts[event.e] then
		self.eventScripts[event.e]:call("event", event)
	end
	self.scripts:call("onEvent", event)
end

function PlayState:pushEvent(name, params)
	if params == nil then
		Toast.error("pushEvent: argument 2 must be the event parameter(s).")
		return
	end

	local path = "data/events/" .. name:gsub(" ", "-"):lower()
	if not self.eventScripts[name] then
		self.eventScripts[name] = Script(path)
		self.scripts:add(self.eventScripts[name])
	end

	self:executeEvent({e = name, v = params})
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
		local time = PlayState.conductor.time + 1000 * dt
		PlayState.conductor:update(time)
		if self.skipConductor then self.skipConductor = false end

		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false

			self:playSong(self.startPos)
			PlayState.conductor.time = self.startPos
			self.scripts:call("songStart")
		else
			local noFocus, events, e = true, self.events
			while events[1] do
				e = events[1]
				if e.t <= game.sound.music.time * 1000 then
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

		if self.startingSong and self.doCountdownAtBeats then
			self:doCountdown(math.floor(
				PlayState.conductor.currentBeatFloat - self.doCountdownAtBeats + 1
			))
		end
	end

	local time = PlayState.conductor.time / 1000
	local missOffset = time - Note.safeZoneOffset / 1.25
	for _, nf in pairs(self.notefields) do
		if nf.is then
			nf.time, nf.beat = time, PlayState.conductor.currentBeatFloat
			local isPlayer = not nf.bot
			local sustainOffset = 0.25 / nf.speed

			for _, note in ipairs(nf:getNotes(time, nil, true)) do
				local hasInput = not isPlayer or controls:down(PlayState.keysControls[note.direction])
				local char = note.character or nf.character

				if note.wasGoodHit then
					if hasInput then
						note.lastPress = time
					end

					if not note.wasGoodSustainHit and note.lastPress then
						local noteEnd = note.time + note.sustainTime
						if noteEnd - sustainOffset <= note.lastPress then
							local fullHeld = noteEnd <= note.lastPress
							if fullHeld or not hasInput then
								self:goodSustainHit(note, time, fullHeld)
								if hasInput and char then
									char.lastHit = PlayState.conductor.time
								end
							end
						elseif not hasInput and isPlayer and note.time <= time then
							self:goodSustainHit(note, time)
							note.tooLate = true
						elseif hasInput and char then
							char.lastHit = PlayState.conductor.time
						end
					end
				elseif isPlayer then
					if not note.wasGoodSustainHit and (note.lastPress or note.time) <= missOffset then
						self:miss(note)
					end
				elseif note.time <= time then
					self:goodNoteHit(note, time)
				end
			end
		end
	end
	self.scripts:call("update", dt)
	PlayState.super.update(self, dt)

	self.camZoomMult = util.coolLerp(self.camZoomMult, 1, 3, dt * self.camZoomSpeed)
	local zoomPlusBop = self.camZoom * self.camZoomMult
	game.camera.zoom = zoomPlusBop

	self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt * self.camZoomSpeed)
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
			game.sound.music.time = time
			for _, notefield in pairs(self.notefields) do
				vocals = notefield.vocals
				if vocals then vocals.time = time end
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
				for _, notefield in pairs(self.notefields) do
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

		game.sound.music.volume = ClientPrefs.data.musicVolume / 100
		local volume, vocals = ClientPrefs.data.vocalVolume / 100
		for _, notefield in pairs(self.notefields) do
			vocals = notefield.vocals
			if vocals then vocals.volume = volume end
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
			local vocals = notefield.vocals
			if vocals then vocals.volume = ClientPrefs.data.vocalVolume / 100 end
		end

		local char = event.character
		if char and not event.cancelledAnim then
			char.waitReleaseAfterSing = not notefield.bot
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
			self.health = math.clamp(self.health + 0.023, 0, 2)
			self.score = self.score + rating.score
			if self.combo >= 10 and rating.resetCombo
				and self.gf and self.gf.animation:has("sad") then
				self.gf:playAnim("sad", true)
				self.gf.lastHit = notefield.time * 1000
			end

			self.combo = (rating.resetCombo and math.min(self.combo, 0) - 1 or
				math.max(self.combo, 0) + 1)

			if self.gf and self.gf.animation:has("combo" .. self.combo) then
				self.gf:playAnim("combo" .. self.combo, true)
				self.gf.lastHit = notefield.time * 1000
			end

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
		notefield.lastSustain = nil
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

		if event.muteVocals and notefield.vocals then notefield.vocals.volume = 0 end

		if event.triggerSound then
			util.playSfx(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)),
				love.math.random(1, 2) / 10)
		end

		local char = event.character
		if char and not event.cancelledAnim then
			char:sing(dir, "miss")
			char.waitReleaseAfterSing = false
		end

		if notefield == self.playerNotefield then
			self.health = math.clamp(self.health - (ghostMiss and 0.04 or 0.0475), 0, 2)
			self.score, self.misses = self.score - 100, self.misses + 1
			if not ghostMiss then
				if self.gf and not event.cancelledSadGF and self.combo >= 10
					and self.gf.animation:has("sad") then
					self.gf:playAnim("sad", true)
					self.gf.lastHit = notefield.time * 1000
				end
				self.combo = math.min(self.combo, 0) - 1
				self:popUpScore()
			end
			self:recalculateRating()
		end
	end
	notefield.lastSustain = nil

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
		if self.buttons then self:remove(self.buttons) end

		GameOverSubstate.characterName = event.characterName
		GameOverSubstate.deathSoundName = event.deathSoundName
		GameOverSubstate.loopSoundName = event.loopSoundName
		GameOverSubstate.endSoundName = event.endSoundName
		GameOverSubstate.deaths = GameOverSubstate.deaths + 1

		self.scripts:call("gameOverCreate")

		if GameOverSubstate.characterName ~= "" then
			local data = Parser.getCharacter(GameOverSubstate.characterName)
			if data then
				paths.async.getImage(data.sprite, function()
					if event.pauseSong then
						self:pauseSong()
					end
					self.paused = event.pauseGame

					self.camHUD.visible, self.camNotes.visible = false, false
					if self.boyfriend then
						self.boyfriend.visible = false
					end
					self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x,
						self.stage.boyfriendPos.y))
					self.scripts:call("postGameOverCreate")
				end)
			end
		end
		Tween.tween(self, {playback = 0}, 1.5, {
			ease = Ease.quadOut,
			onUpdate = function() self:setPlayback() end
		})

		self.isDead = true
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
	for _, notefield in pairs(self.notefields) do
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
	for _, notefield in pairs(self.notefields) do
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

	local event = self.scripts:call("endSong")
	if event == Script.Event_Cancel then return end

	game.sound.music:reset(true)
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals then notefield.vocals:stop() end
	end

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
		local endTimestamp = (startTimestamp + game.sound.music.duration) - PlayState.conductor.time / 1000
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
	PlayState.conductor:destroy()
	PlayState.conductor = nil

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	self.scripts:call("postLeave")
	self.scripts:close()
end

return PlayState
