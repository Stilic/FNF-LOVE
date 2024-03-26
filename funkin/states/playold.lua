local PauseSubstate = require "funkin.substates.pause"
local Events = require "funkin.backend.scripting.events"

---@class PlayState:State
local PlayState = State:extend("PlayState")

PlayState.defaultDifficulty = "normal"

PlayState.controlDirs = {
	note_left = 0,
	note_down = 1,
	note_up = 2,
	note_right = 3
}
PlayState.ratings = {
	{name = "sick", time = 45,        score = 350, splash = true,  mod = 1},
	{name = "good", time = 90,        score = 200, splash = false, mod = 0.7},
	{name = "bad",  time = 135,       score = 100, splash = false, mod = 0.4},
	{name = "shit", time = math.huge, score = 50,  splash = false, mod = 0.2}
}
PlayState.notePosition = 0

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
	local metadata = paths.getJSON('songs/' .. song .. '/meta')

	if data then
		PlayState.SONG = data.song
		if metadata then PlayState.SONG.meta = metadata end
	else
		if metadata == nil then return false end
		PlayState.SONG = {
			song = song,
			bpm = metadata.bpm or 150,
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

function PlayState.getFieldPosition(fieldCount, keyCount, downScroll)
	local swagWidth = Note.swagWidth - (fieldCount > 2 and 5 or 0)
	local separation = math.max(swagWidth * keyCount, game.width / math.pow(2, fieldCount - 1)) - (fieldCount > 2 and 1 or 0)
	local rx, ry = game.width / 2 - (separation * (fieldCount - 1) + swagWidth * keyCount) / 2, 50
	if downScroll then ry = game.height - 100 - ry end
	return rx, ry, swagWidth, separation
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
	if PlayState.SONG == nil then PlayState.loadSong("test") end
	local songName = paths.formatToSongPath(PlayState.SONG.song)

	PlayState.conductor = Conductor():setSong(PlayState.SONG)
	PlayState.conductor.onStep = bind(self, self.step)
	PlayState.conductor.onBeat = bind(self, self.beat)
	PlayState.conductor.onSection = bind(self, self.section)

	self.keyCount = 4

	self.scoreFormat = "Score: %score // Combo Breaks: %misses // %accuracy% - %rating"
	self.scoreFormatVariables = {score = 0, misses = 0, accuracy = 0, rating = 0}

	self.timer = Timer.new()

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts", "data/scripts/" .. songName, "songs/" .. songName)

	self.scripts:set("curSection", PlayState.conductor.currentSection)
	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	self.scripts:call("create")

	self.playback = 1
	Timer.setSpeed(1)

	game.sound.loadMusic(paths.getInst(songName))
	game.sound.music:setLooping(false)
	game.sound.music.onComplete = function() self:endSong() end

	if PlayState.SONG.needsVoices then
		self.vocals = Sound():load(paths.getVoices(songName))
		game.sound.list:add(self.vocals)
	end

	self.keysPressed = {}

	self.unspawnNotes = {}
	self.allNotes = Group()
	self.notesGroup = Group()
	self.sustainsGroup = Group()

	self.isDead = false
	GameOverSubstate.resetVars()

	self.botPlay = ClientPrefs.data.botplayMode
	self.downScroll = ClientPrefs.data.downScroll
	self.middleScroll = ClientPrefs.data.middleScroll

	PlayState.pixelStage = false
	PlayState.SONG.stage = self:loadStageWithSongName(songName)

	self.stage = Stage(PlayState.SONG.stage)
	self:add(self.stage)
	self.scripts:add(self.stage.script)

	for _, s in ipairs(PlayState.SONG.notes) do
		if s and s.sectionNotes then
			for _, n in ipairs(s.sectionNotes) do
				local daStrumTime = tonumber(n[1])
				local daNoteData = tonumber(n[2])
				if daStrumTime ~= nil and daNoteData ~= nil and daStrumTime >= self.startPos then
					daNoteData = daNoteData % 4
					local gottaHitNote = s.mustHitSection
					if n[2] > 3 then
						gottaHitNote = not gottaHitNote
					end

					local oldNote
					if #self.unspawnNotes > 0 then
						oldNote = self.unspawnNotes[#self.unspawnNotes]
					end

					local note = Note(daStrumTime, daNoteData, oldNote)
					note.mustPress = gottaHitNote
					note.type = n[4]
					note:setScrollFactor()
					if self.middleScroll and not note.mustPress then note.visible = false end
					table.insert(self.unspawnNotes, note)

					if n[3] ~= nil then
						local susLength = tonumber(n[3])
						if susLength ~= nil and susLength > 0 then
							susLength = math.round(susLength / PlayState.conductor.stepCrotchet)
							if susLength > 0 then
								for susNote = 0, math.max(susLength - 1, 1) do
									oldNote =
										self.unspawnNotes[#self.unspawnNotes]

									local sustain = Note(daStrumTime +
										PlayState.conductor
										.stepCrotchet *
										(susNote + 1),
										daNoteData, oldNote,
										true, note)
									sustain.mustPress = note.mustPress
									sustain.type = note.type
									sustain:setScrollFactor()
									if self.middleScroll and not sustain.mustPress then
										sustain.visible = false
									end
									table.insert(self.unspawnNotes, sustain)
								end
							end
						end
					end
				end
			end
		end
	end

	table.sort(self.unspawnNotes, Conductor.sortByTime)

	PlayState.conductor.time = self.startPos - (PlayState.conductor.crotchet * 5)

	self.score = 0
	self.combo = 0
	self.misses = 0
	self.accuracy = 0
	self.health = 1

	-- for ratings
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0

	self.totalPlayed = 0
	self.totalHit = 0.0

	self.camHUD = Camera()
	self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100
	self.camOther = Camera()
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camOther, false)

	self.receptors = Group()
	self.playerReceptors = Group()
	self.enemyReceptors = Group()

	local rx, ry, swagWidth, separation = PlayState.getFieldPosition(self.middleScroll and 1 or 2, self.keyCount, self.downScroll)
	for i = 0, 1, 1 do
		local x, isPlayer = rx + separation * i, i == 1
		if self.middleScroll then
			isPlayer = not isPlayer
		end
		for j = 0, self.keyCount - 1, 1 do
			local rep = Receptor(x + swagWidth * j,
				ry, j, i)
			rep:setScrollFactor()
			self.receptors:add(rep)
			if isPlayer then
				self.playerReceptors:add(rep)
			else
				if self.middleScroll then
					rep.visible = false
				end
				self.enemyReceptors:add(rep)
			end
		end
	end

	self.splashes = Group()

	local splash = NoteSplash()
	splash.alpha = 0
	self.splashes:add(splash)

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
	self.judgement = Judgement(self.stage.ratingPos.x, self.stage.ratingPos.y)
	self:add(self.judgement)

	self.camFollow = {x = 0, y = 0, set = function(this, x, y)
		this.x = x
		this.y = y
	end}
	self:cameraMovement()

	if PlayState.prevCamFollow ~= nil then
		self.camFollow:set(PlayState.prevCamFollow.x, PlayState.prevCamFollow.y)
		PlayState.prevCamFollow = nil
	end
	game.camera:follow(self.camFollow, nil, 2.4 * self.stage.camSpeed)
	game.camera:snapToTarget()

	self.camZooming = false
	game.camera.zoom = self.stage.camZoom

	self.healthBarBG = Sprite()
	self.healthBarBG:loadTexture(paths.getImage("skins/normal/healthBar"))
	self.healthBarBG:updateHitbox()
	self.healthBarBG:screenCenter("x")
	self.healthBarBG.y = game.height * 0.9
	self.healthBarBG:setScrollFactor()

	self.healthBar = Bar(self.healthBarBG.x + 4, self.healthBarBG.y + 4,
		math.floor(self.healthBarBG.width - 8),
		math.floor(self.healthBarBG.height - 8), 0, 2, true)
	self.healthBar:setValue(self.health)
	self.healthBar.color = self.boyfriend.iconColor ~= nil and Color.fromString(self.boyfriend.iconColor) or Color.GREEN
	self.healthBar.color.bg = self.dad.iconColor ~= nil and Color.fromString(self.dad.iconColor) or Color.RED

	self.iconP1 = HealthIcon(self.boyfriend.icon, true)
	self.iconP1.y = self.healthBar.y - 75

	self.iconP2 = HealthIcon(self.dad.icon, false)
	self.iconP2.y = self.healthBar.y - 75

	local fontScore = paths.getFont("vcr.ttf", 17)
	self.scoreTxt = Text(game.width / 2, self.healthBarBG.y + 44, "", fontScore, {1, 1, 1},
		"center")
	self.scoreTxt.outline.width = 1
	self.scoreTxt.antialiasing = false

	self.timeArc = ProgressArc(36, game.height - 81, 65, 18, {Color.BLACK, Color.WHITE}, 0, game.sound.music:getDuration() / 1000)

	local songTime = 0
	if ClientPrefs.data.timeType == "left" then
		songTime = game.sound.music:getDuration() - songTime
	end

	local fontTime = paths.getFont("vcr.ttf", 24)
	self.timeTxt = Text((self.timeArc.x + self.timeArc.width) + 4, 0, util.formatTime(songTime),
		fontTime, {1, 1, 1}, "left")
	self.timeTxt.outline.width = 2
	self.timeTxt.antialiasing = false
	self.timeTxt.y = (self.timeArc.y + self.timeArc.width) - self.timeTxt:getHeight()

	self.botplayTxt = Text(604, self.timeTxt.y, 'BOTPLAY MODE',
		fontTime, {1, 1, 1}, "right", game.width / 2)
	self.botplayTxt.outline.width = 2
	self.botplayTxt.antialiasing = false
	self.botplayTxt.visible = self.botPlay

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
			cameras = {self.camOther},
			fill = "line",
			lined = false,
			config = {
				round = {0, 0}
			}
		})
		self.buttons:disable()
	end

	self:add(self.receptors)
	self:add(self.sustainsGroup)
	self:add(self.notesGroup)
	self:add(self.splashes)

	self:add(self.healthBarBG)
	self:add(self.healthBar)
	self:add(self.iconP1)
	self:add(self.iconP2)
	self:add(self.scoreTxt)
	self:add(self.timeArc)
	self:add(self.timeTxt)
	self:add(self.botplayTxt)

	if self.buttons then self:add(self.buttons) end

	self:recalculateRating()

	for _, o in ipairs({
		self.receptors, self.splashes, self.notesGroup, self.sustainsGroup,
		self.healthBarBG, self.healthBar, self.iconP1, self.iconP2,
		self.scoreTxt, self.timeArc, self.timeTxt, self.botplayTxt
	}) do o.cameras = {self.camHUD} end

	if self.downScroll then
		for _, o in ipairs({
			self.healthBarBG, self.healthBar, self.iconP1, self.iconP2,
			self.scoreTxt, self.timeArc, self.timeTxt, self.botplayTxt
		}) do o.y = -o.y + (o.offset.y * 2) + game.height - (o.getHeight and o:getHeight() or o.height) end
	end

	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = function(...) self:onKeyPress(...) end
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = function(...) self:onKeyRelease(...) end
	controls:bindRelease(self.bindedKeyRelease)

	self.startingSong = true
	self.startedCountdown = false

	if self.storyMode and not PlayState.seenCutscene then
		PlayState.seenCutscene = true

		local cutscenePaths = {paths.getMods('data/cutscenes/' .. songName .. '.lua'),
			paths.getMods('data/cutscenes/' .. songName .. '.json'),
			paths.getPath('data/cutscenes/' .. songName .. '.lua'),
			paths.getPath('data/cutscenes/' .. songName .. '.json')}

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

	if Discord then
		local detailsText = "Freeplay"
		if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

		local diff = PlayState.defaultDifficulty
		if PlayState.songDifficulty ~= "" then
			diff = PlayState.songDifficulty:gsub("^%l", string.upper)
		end

		Discord.changePresence({
			details = detailsText,
			state = PlayState.getSongName() .. ' - [' .. diff .. ']'
		})
	end

	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	PlayState.super.enter(self)
	self.scripts:call("postCreate")
end

function PlayState:startCountdown()
	if self.buttons then
		self.buttons:enable()
	end

	local event = self.scripts:call("startCountdown")
	if event == Script.Event_Cancel then return end

	self.playback = ClientPrefs.data.playback
	Timer.setSpeed(self.playback)
	game.sound.music:setPitch(self.playback)
	if self.vocals then
		self.vocals:setPitch(self.playback)
	end

	self.startedCountdown = true
	game.camera:follow(self.camFollow, nil, 2.4 * self.stage.camSpeed)

	local basePath = "skins/" .. (PlayState.pixelStage and "pixel" or "normal")
	local countdownData, crotchet = {
		{sound = basePath .. "/intro3",  image = nil},
		{sound = basePath .. "/intro2",  image = basePath .. "/ready"},
		{sound = basePath .. "/intro1",  image = basePath .. "/set"},
		{sound = basePath .. "/introGo", image = basePath .. "/go"}
	}, PlayState.conductor.crotchet / 1000
	for swagCounter = 0, #countdownData do
		local sussyCounter = swagCounter + 1 -- funny word huh
		self.timer:after(crotchet * sussyCounter, function()
			self.scripts:call("countdownTick", swagCounter)

			local data = countdownData[sussyCounter]
			if data then
				if data.sound then
					game.sound.play(paths.getSound(data.sound)):setPitch(self.playback)
				end
				if data.image then
					local countdownSprite = Sprite()
					countdownSprite:loadTexture(paths.getImage(data.image))
					countdownSprite.cameras = {self.camHUD}
					if PlayState.pixelStage then
						countdownSprite.scale = {x = 6, y = 6}
					end
					countdownSprite:updateHitbox()
					countdownSprite.antialiasing = not PlayState.pixelStage
					countdownSprite:screenCenter()

					Timer.tween(crotchet, countdownSprite, {alpha = 0},
						"in-out-cubic", function()
							self:remove(countdownSprite)
							countdownSprite:destroy()
						end)
					self:add(countdownSprite)
				end
			end

			self.boyfriend:beat(swagCounter)
			self.gf:beat(swagCounter)
			self.dad:beat(swagCounter)

			self.scripts:call("postCountdownTick", swagCounter)
		end)
	end
end

function PlayState:update(dt)
	dt = dt * self.playback
	self.lastTick = love.timer.getTime()

	self.scripts:call("update", dt)

	self.timer:update(dt)

	if self.startedCountdown then
		PlayState.conductor.time = PlayState.conductor.time + dt * 1000
		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false
			self.playback = ClientPrefs.data.playback -- reload playback for countdown skip
			Timer.setSpeed(self.playback)

			game.sound.music:setPitch(self.playback)
			game.sound.music:seek(self.startPos / 1000)
			game.sound.music:play()

			if self.vocals then
				self.vocals:setPitch(self.playback)
				self.vocals:seek(game.sound.music:tell())
				self.vocals:play()
			end
			self.scripts:call("songStart")
		end
	end

	PlayState.notePosition = PlayState.conductor.time

	if not self.startingSong then
		PlayState.conductor:update()
	end

	PlayState.super.update(self, dt)

	if self.startedCountdown then
		self:cameraMovement()
	end

	local mult = util.coolLerp(self.iconP1.scale.x, 1, 15, dt)
	self.iconP1.scale = {x = mult, y = mult}
	self.iconP2.scale = {x = mult, y = mult}

	self.iconP1:updateHitbox()
	self.iconP2:updateHitbox()

	local iconOffset = 26
	self.iconP1.x = self.healthBar.x + (self.healthBar.width *
		(math.remapToRange(self.healthBar.percent, 0, 100, 100,
			0) * 0.01) - iconOffset)

	self.iconP2.x = self.healthBar.x + (self.healthBar.width *
			(math.remapToRange(self.healthBar.percent, 0, 100, 100,
				0) * 0.01)) -
		(self.iconP2.width - iconOffset)

	self.iconP1:setState((self.health < 0.2 and 2 or 1))
	self.iconP2:setState((self.health > 1.8 and 2 or 1))

	-- time arc / text
	local songTime = PlayState.conductor.time / 1000

	if ClientPrefs.data.timeType == "left" then
		songTime = game.sound.music:getDuration() - songTime
	end

	if PlayState.conductor.time > 0 and
		PlayState.conductor.time < game.sound.music:getDuration() * 1000 then
		self.timeTxt.content = util.formatTime(songTime)
		self.timeArc.tracker = PlayState.conductor.time / 1000
	end

	if self.camZooming then
		game.camera.zoom = util.coolLerp(game.camera.zoom, self.stage.camZoom, 3, dt)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt)
	end

	if self.startedCountdown then
		if (self.buttons and game.keys.justPressed.ESCAPE) or controls:pressed("pause") then
			local event = self.scripts:call("paused")
			if event ~= Script.Event_Cancel then
				game.camera:unfollow()

				game.sound.music:pause()
				if self.vocals then self.vocals:pause() end

				self.paused = true

				if Discord then
					local detailsText = "Freeplay"
					if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

					local diff = PlayState.defaultDifficulty
					if PlayState.songDifficulty ~= "" then
						diff = PlayState.songDifficulty:gsub("^%l", string.upper)
					end

					Discord.changePresence({
						details = "Paused - " .. detailsText,
						state = PlayState.getSongName() .. ' - [' .. diff .. ']'
					})
				end

				if self.buttons then
					self.buttons:disable()
				end

				local pause = PauseSubstate()
				pause.cameras = {self.camOther}
				self:openSubstate(pause)
			end
		end
		if controls:pressed("debug_1") then
			game.camera:unfollow()
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			game.switchState(ChartingState())
		end
		--[[if controls:pressed("debug_2") then
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			CharacterEditor.onPlayState = true
			game.switchState(CharacterEditor())
		end]]
		if controls:pressed("reset") then self.health = 0 end
	end

	if self.health <= 0 and not self.isDead then
		local event = self.scripts:event("onGameOver", Events.GameOver())
		if not event.cancelled then
			self.paused = event.pauseGame

			if event.pauseSong then
				game.sound.music:pause()
				if self.vocals then self.vocals:pause() end
			end

			if Discord then
				local detailsText = "Freeplay"
				if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

				local diff = PlayState.defaultDifficulty
				if PlayState.songDifficulty ~= "" then
					diff = PlayState.songDifficulty:gsub("^%l", string.upper)
				end

				Discord.changePresence({
					details = "Game Over - " .. detailsText,
					state = PlayState.getSongName() .. ' - [' .. diff .. ']'
				})
			end

			self.camHUD.visible = false
			self.boyfriend.visible = false

			if self.buttons then
				self.buttons:disable()
			end

			GameOverSubstate.characterName = event.characterName
			GameOverSubstate.deathSoundName = event.deathSoundName
			GameOverSubstate.loopSoundName = event.loopSoundName
			GameOverSubstate.endSoundName = event.endSoundName

			self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x,
				self.stage.boyfriendPos.y))
			self.isDead = true
		end
	end

	if self.unspawnNotes[1] then
		local time = 2000
		if PlayState.SONG.speed < 1 then
			time = time / PlayState.SONG.speed
		end
		while #self.unspawnNotes > 0 and self.unspawnNotes[1].time -
			PlayState.notePosition < time do
			local n = table.remove(self.unspawnNotes, 1)
			local grp = n.isSustain and self.sustainsGroup or self.notesGroup
			self.allNotes:add(n)
			grp:add(n)
		end
	end

	local n
	for i = 1, #self.allNotes.members do
		n = self.allNotes.members[i]
		if n == nil then break end

		if not self.startingSong and not n.tooLate and
			not n.ignoreNote and ((not n.mustPress or self.botPlay) and
				(not n.isSustain or not n.parentNote or n.parentNote.wasGoodHit) and
				((n.isSustain and n.canBeHit) or n.time <=
					PlayState.notePosition) or
				(n.isSustain and n.canBeHit and self.keysPressed[n.data])) then
			self:goodNoteHit(n)
		end

		self:updateNote(n)

		if PlayState.notePosition > 350 / PlayState.SONG.speed + n.time then
			if not n.ignoreNote and n.mustPress and not n.wasGoodHit and
				(not n.isSustain or not n.parentNote.tooLate) then
				self:noteMiss(n)
			end

			self:removeNote(n)
		end
	end

	if Project.DEBUG_MODE then
		if game.keys.justPressed.TWO then self:endSong() end
		if game.keys.justPressed.ONE then self.botPlay = not self.botPlay end
	end

	self.scripts:call("postUpdate", dt)
end

-- Notes need a rework, which im doing but gets disturbed with everything else first instead
--- ralty
function PlayState:updateNote(n)
	local ogCrotchet = (60 / PlayState.SONG.bpm) * 1000
	local ogStepCrotchet, time = ogCrotchet / 4, n.time
	if n.isSustain and PlayState.SONG.speed ~= 1 then
		time = time - ogStepCrotchet + ogStepCrotchet / PlayState.SONG.speed
	end

	local r = (n.mustPress and self.playerReceptors or self.enemyReceptors).members[n.data + 1]
	local sy = r.y + n.scrollOffset.y

	n.x = r.x + n.scrollOffset.x
	n.y = sy - (PlayState.notePosition - time) *
		(0.45 * PlayState.SONG.speed) * (self.downScroll and -1 or 1)

	if n.isSustain then
		n.flipY = self.downScroll
		if n.flipY then
			if n.isSustainEnd then
				n.y = n.y + (43.5 * 0.7) * (PlayState.conductor.stepCrotchet / 100 * 1.5 *
					PlayState.SONG.speed) - n.height
			end
			n.y = n.y + Note.swagWidth / 2 - 60.5 * (PlayState.SONG.speed - 1) + 27.5 *
				(PlayState.SONG.bpm / 100 - 1) * (PlayState.SONG.speed - 1)
		else
			n.y = n.y + Note.swagWidth / 12
		end

		if (n.wasGoodHit or n.prevNote.wasGoodHit) and
			(not n.mustPress or self.botPlay or self.keysPressed[n.data] or n.isSustainEnd)
		then
			local center = sy + Note.swagWidth / 2
			local vert = center - n.y
			if self.downScroll then
				if n.y - n.offset.y + n:getFrameHeight() * n.scale.y >= center then
					if not n.clipRect then n.clipRect = {} end
					n.clipRect.x, n.clipRect.y = 0, 0
					n.clipRect.width, n.clipRect.height = n:getFrameWidth() * n.scale.x, vert
				end
			elseif n.y + n.offset.y <= center then
				if not n.clipRect then n.clipRect = {} end
				n.clipRect.x, n.clipRect.y = 0, vert
				n.clipRect.width, n.clipRect.height =
					n:getFrameWidth() * n.scale.x,
					n:getFrameHeight() * n.scale.y - vert
			end
		end
	end
end

function PlayState:updateNotes()
	for i = 1, #self.allNotes.members do
		self:updateNote(self.allNotes.members[i])
	end
end

function PlayState:cameraMovement()
	local section = PlayState.SONG.notes[PlayState.conductor.currentSection + 1]
	local target
	if section ~= nil then
		local camX, camY
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

function PlayState:draw()
	self.scripts:call("draw")
	PlayState.super.draw(self)
	self.scripts:call("postDraw")
end

function PlayState:closeSubstate()
	PlayState.super.closeSubstate(self)
	if not self.startingSong then
		game.camera:follow(self.camFollow, nil, 2.4 * self.stage.camSpeed)

		if self.vocals and not self.startingSong then
			self.vocals:seek(game.sound.music:tell())
		end
		game.sound.music:play()
		if self.vocals then self.vocals:play() end

		if Discord then
			local detailsText = "Freeplay"
			if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

			local startTimestamp = os.time(os.date("*t"))
			local endTimestamp = startTimestamp +
				game.sound.music:getDuration()
			endTimestamp = endTimestamp - PlayState.conductor.time / 1000

			local diff = PlayState.defaultDifficulty
			if PlayState.songDifficulty ~= "" then
				diff = PlayState.songDifficulty:gsub("^%l", string.upper)
			end

			Discord.changePresence({
				details = detailsText,
				state = PlayState.getSongName() .. ' - [' .. diff .. ']',
				startTimestamp = math.floor(startTimestamp),
				endTimestamp = math.floor(endTimestamp)
			})
		end
	end

	if self.buttons then
		self.buttons:enable()
	end
end

function PlayState:onSettingChange(category, setting)
	if category == "gameplay" then
		switch(setting, {
			["downScroll"]=function()
				self.downScroll = ClientPrefs.data.downScroll

				self.healthBarBG.y = game.height * 0.9
				self.healthBar.y = self.healthBarBG.y + 4

				self.iconP1.y = self.healthBar.y - 75
				self.iconP2.y = self.healthBar.y - 75

				self.scoreTxt.y = self.healthBarBG.y + 44

				self.timeArc.y = game.height - 81
				self.timeTxt.y = (self.timeArc.y + self.timeArc.width) - self.timeTxt:getHeight()

				self.botplayTxt.y = self.timeTxt.y

				if self.downScroll then
					local lastIconScale = self.iconP1.scale.x
					self.iconP1.scale = {x = 1, y = 1}
					self.iconP2.scale = {x = 1, y = 1}

					self.iconP1:updateHitbox()
					self.iconP2:updateHitbox()

					for _, o in ipairs({
						self.healthBarBG, self.healthBar, self.iconP1, self.iconP2,
						self.scoreTxt, self.timeArc, self.timeTxt, self.botplayTxt
					}) do o.y = -o.y + (o.offset.y * 2) + game.height - (o.getHeight and o:getHeight() or o.height) end

					self.iconP1.scale = {x = lastIconScale, y = lastIconScale}
					self.iconP2.scale = {x = lastIconScale, y = lastIconScale}

					self.iconP1:updateHitbox()
					self.iconP2:updateHitbox()
				end
			end,
			["middleScroll"]=function()
				self.middleScroll = ClientPrefs.data.middleScroll

				for _, rep in ipairs(self.receptors.members) do
					rep.visible = not self.middleScroll or rep.player == 0
				end

				local n
				for i = 1, #self.unspawnNotes do
					n = self.unspawnNotes[i]
					n.visible = not self.middleScroll or n.mustPress
				end

				for i = 1, #self.allNotes.members do
					n = self.allNotes.members[i]
					n.visible = not self.middleScroll or n.mustPress
				end
			end,
			["botplayMode"]=function()
				self.botPlay = ClientPrefs.data.botplayMode
				self.botplayTxt.visible = self.botPlay
			end,
			["backgroundDim"]=function()
				self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100
			end,
			["playback"]=function()
				self.playback = ClientPrefs.data.playback
				Timer.setSpeed(self.playback)
				game.sound.music:setPitch(self.playback)
				if self.vocals then
					self.vocals:setPitch(self.playback)
				end
			end,
			["timeType"]=function()
				local songTime = PlayState.conductor.time / 1000
				if ClientPrefs.data.timeType == "left" then
					songTime = game.sound.music:getDuration() - songTime
				end
				self.timeTxt.content = util.formatTime(songTime)
			end,
		})

		if setting == "downScroll" or setting == "middleScroll" then
			local rx, ry, swagWidth, separation = PlayState.getFieldPosition(self.middleScroll and 1 or 2, self.keyCount, self.downScroll)
			for _, rep in ipairs(self.receptors.members) do
				rep:setPosition(rx + separation * rep.player + swagWidth * rep.data,
					ry)
			end
			self:updateNotes()
		end
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

function PlayState:getKeyFromEvent(controls)
	for _, control in pairs(controls) do
		if PlayState.controlDirs[control] then
			return PlayState.controlDirs[control]
		end
	end
	return -1
end

function PlayState:onKeyPress(key, type, scancode, isrepeat, time)
	if self.botPlay or (self.substate and not self.persistentUpdate) then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)

	if key < 0 then return end
	self.keysPressed[key] = true

	-- the most closest thing possible to sub-precision ms
	local prev = PlayState.conductor.time
	local time = prev + (time - self.lastTick) * game.sound.music:getActualPitch()
	PlayState.conductor.time = time

	local noteList = {}
	for _, n in ipairs(self.notesGroup.members) do
		if n.mustPress and not n.isSustain and not n.tooLate and not n.wasGoodHit then
			if not n.canBeHit and n:checkDiff(PlayState.conductor.time) then
				n:update(0)
			end
			if n.canBeHit and n.data == key then
				table.insert(noteList, n)
			end
		end
	end

	if #noteList > 0 then
		table.sort(noteList, Conductor.sortByTime)
		local coolNote = table.remove(noteList, 1)

		for _, n in pairs(noteList) do
			if n.time - coolNote.time <= 1 then
				self:goodNoteHit(n)
			end
		end

		self:goodNoteHit(coolNote)

		if ClientPrefs.data.hitSound > 0 then
			game.sound.play(paths.getSound('hitsound'), ClientPrefs.data.hitSound / 100)
		end
	end

	PlayState.conductor.time = prev

	local r = self.playerReceptors.members[key + 1]
	if r and r.curAnim.name ~= "confirm" then
		r:play("pressed")
	end
end

function PlayState:onKeyRelease(key, type)
	if self.botPlay or (self.substate and not self.persistentUpdate) then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)

	if key < 0 then return end
	self.keysPressed[key] = false

	local r = self.playerReceptors.members[key + 1]
	if r then
		r:play("static")
		r.confirmTimer = 0
	end
end

function PlayState:noteMiss(n)
	self.scripts:call("noteMiss", n)

	local event
	event = self.scripts:event("onNoteMiss", Events.NoteMiss(n, (n.mustPress and self.boyfriend or self.dad)))

	if not event.cancelled then
		if event.muteVocals and self.vocals then self.vocals:setVolume(0) end

		if self.combo > 0 then self.combo = 0 end
		self.combo = self.combo - 1
		self.score = self.score - 100
		self.misses = self.misses + 1

		self.totalPlayed = self.totalPlayed + 1

		local np = n.isSustain and n.parentNote or n
		np.tooLate = true
		for _, no in ipairs(np.children) do
			no.tooLate = true
		end

		self.health = self.health - 0.0475
		if self.health < 0 then self.health = 0 end
		self.healthBar:setValue(self.health)

		if not event.cancelledAnim then
			self.boyfriend:sing(n.data, "miss")
		end

		if not event.cancelledSadGF and self.gf.__animations['sad'] then
			self.gf:playAnim('sad', true)
			self.gf.lastHit = PlayState.conductor.currentBeat
		end
		self:recalculateRating()
	end

	self.scripts:call("postNoteMiss", n)
end

function PlayState:goodNoteHit(n)
	if not n.wasGoodHit then
		n.wasGoodHit = true
		self.scripts:call("goodNoteHit", n)

		local event
		event = self.scripts:event("onNoteHit", Events.NoteHit(n, (n.mustPress and self.boyfriend or self.dad)))

		if not event.cancelled then
			if event.unmuteVocals and self.vocals then self.vocals:setVolume(1) end

			local animType = ''
			if PlayState.SONG.notes[PlayState.conductor.currentSection + 1].altAnim then
				animType = 'alt'
			end

			if not event.cancelledAnim then
				local char = (n.mustPress and self.boyfriend or self.dad)
				char:sing(n.data, animType)
			end

			if paths.formatToSongPath(self.SONG.song) ~= 'tutorial' then
				if not n.mustPress then self.camZooming = true end
			end

			local receptor = (n.mustPress and self.playerReceptors or
				self.enemyReceptors).members[n.data + 1]

			if not event.strumGlowCancelled then
				receptor:play("confirm", true)
				if not n.mustPress or self.botPlay then
					receptor.holdTime = (not n.isSustain or n.isSustainEnd) and 0.14 or 0
				end
			end

			if n.mustPress and not n.ignoreNote then
				self.health = self.health + (n.isSustain and 0.013 or 0.023)
				if self.health > 2 then self.health = 2 end
				self.healthBar:setValue(self.health)
			end

			if not n.isSustain then
				if n.mustPress then
					local diff, rating = math.abs(n.time - PlayState.conductor.time),
						PlayState.ratings[#PlayState.ratings - 1]
					for _, r in pairs(PlayState.ratings) do
						if diff <= r.time then
							rating = r
							break
						end
					end

					if not n.ignoreNote then
						if self.combo < 0 then self.combo = 0 end
						self.combo = self.combo + 1
						self.score = self.score + rating.score
					end

					if ClientPrefs.data.noteSplash and rating.splash then
						local splash = self.splashes:recycle(NoteSplash)
						splash.x, splash.y = receptor.x, receptor.y
						splash:setup(n.data)
					end

					self.totalHit = self.totalHit + rating.mod
					self.totalPlayed = self.totalPlayed + 1
					self:recalculateRating(rating.name)
				end

				self:removeNote(n)
			end
		end

		self.scripts:call("postGoodNoteHit", n)
	end
end

function PlayState:endSong(skip)
	if skip == nil then skip = false end
	PlayState.seenCutscene = false
	self.startedCountdown = false

	if self.storyMode and not PlayState.seenCutscene and not skip then
		PlayState.seenCutscene = true

		local songName = paths.formatToSongPath(PlayState.SONG.song)
		local cutscenePaths = {paths.getMods('data/cutscenes/' .. songName .. '-end.lua'),
			paths.getMods('data/cutscenes/' .. songName .. '-end.json'),
			paths.getPath('data/cutscenes/' .. songName .. '-end.lua'),
			paths.getPath('data/cutscenes/' .. songName .. '-end.json')}

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

	local formatSong = paths.formatToSongPath(self.SONG.song)
	Highscore.saveScore(formatSong, self.score, self.songDifficulty)

	if self.chartingMode then
		game.switchState(ChartingState())
		return
	end

	if self.storyMode then
		PlayState.storyScore = PlayState.storyScore + self.score

		table.remove(PlayState.storyPlaylist, 1)

		if #PlayState.storyPlaylist > 0 then
			PlayState.prevCamFollow = {
				x = game.camera.target.x,
				y = game.camera.target.y
			}
			game.sound.music:stop()
			if self.vocals then self.vocals:stop() end

			if love.system.getDevice() == 'Desktop' then
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
			game.sound.music:setPitch(1)
			game.sound.playMusic(paths.getMusic("freakyMenu"))
		end
	else
		game.camera:unfollow()
		game.switchState(FreeplayState())
		game.sound.music:setPitch(1)
		game.sound.playMusic(paths.getMusic("freakyMenu"))
	end

	self.scripts:call("postEndSong")
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

function PlayState:step(s)
	if self.startedCountdown and not self.startingSong and game.sound.music:isPlaying() then
		local time = game.sound.music:tell() * 1000
		if self.vocals and math.abs((self.vocals:tell() * 1000) - time) > 20 then
			self.vocals:seek(time / 1000)
		end
		if math.abs(time - PlayState.conductor.time) > 20 then
			PlayState.conductor.time = time
		end

		if Discord then
			local detailsText = "Freeplay"
			if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

			local startTimestamp = os.time(os.date("*t"))
			local endTimestamp = startTimestamp +
				game.sound.music:getDuration()
			endTimestamp = endTimestamp - PlayState.conductor.time / 1000

			local diff = PlayState.defaultDifficulty
			if PlayState.songDifficulty ~= "" then
				diff = PlayState.songDifficulty:gsub("^%l", string.upper)
			end

			Discord.changePresence({
				details = detailsText,
				state = PlayState.getSongName() .. ' - [' .. diff .. ']',
				startTimestamp = math.floor(startTimestamp),
				endTimestamp = math.floor(endTimestamp)
			})
		end
	end
	self.scripts:set("curStep", s)
	self.scripts:call("step")
	self.scripts:call("postStep")
end

function PlayState:beat(b)
	self.scripts:set("curBeat", b)
	self.scripts:call("beat")

	local scaleNum = 1.2
	self.iconP1.scale = {x = scaleNum, y = scaleNum}
	self.iconP2.scale = {x = scaleNum, y = scaleNum}

	self.boyfriend:beat(b)
	self.gf:beat(b)
	self.dad:beat(b)

	self.scripts:call("postBeat", b)
end

function PlayState:section(s)
	self.scripts:set("curSection", s)
	self.scripts:call("section")

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
	if Discord then
		if f then
			local detailsText = "Freeplay"
			if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

			local startTimestamp = os.time(os.date("*t"))
			local endTimestamp = startTimestamp +
				game.sound.music:getDuration()
			endTimestamp = endTimestamp - PlayState.conductor.time / 1000

			local diff = PlayState.defaultDifficulty
			if PlayState.songDifficulty ~= "" then
				diff = PlayState.songDifficulty:gsub("^%l", string.upper)
			end

			Discord.changePresence({
				details = detailsText,
				state = PlayState.getSongName() .. ' - [' .. diff .. ']',
				startTimestamp = math.floor(startTimestamp),
				endTimestamp = math.floor(endTimestamp)
			})
		else
			local detailsText = "Freeplay"
			if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

			local diff = PlayState.defaultDifficulty
			if PlayState.songDifficulty ~= "" then
				diff = PlayState.songDifficulty:gsub("^%l", string.upper)
			end

			Discord.changePresence({
				details = "Paused - " .. detailsText,
				state = PlayState.getSongName() .. ' - [' .. diff .. ']'
			})
		end
	end
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
				game.camera:follow(self.camFollow, nil, 2.4 * self.stage.camSpeed)
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

local ratingFormat, noRating = "(%s) %s", "?"
function PlayState:recalculateRating(rating)
	if rating then
		local ratingAdd = rating .. "s"
		if self[ratingAdd] then self[ratingAdd] = self[ratingAdd] + 1 end
	end

	local ratingStr = noRating
	if self.totalPlayed > 0 then
		local accuracy, class = math.min(1, math.max(0, self.totalHit / self.totalPlayed))
		if accuracy >= 1 then class = "X"
		elseif accuracy >= 0.99 then class = "S+"
		elseif accuracy >= 0.95 then class = "S"
		elseif accuracy >= 0.90 then class = "A"
		elseif accuracy >= 0.80 then class = "B"
		elseif accuracy >= 0.70 then class = "C"
		elseif accuracy >= 0.60 then class = "D"
		elseif accuracy >= 0.50 then class = "E"
		else class = "F" end
		self.accuracy = accuracy

		local fc
		if self.misses < 1 then
			if self.bads > 0 or self.shits > 0 then fc = "FC"
			elseif self.goods > 0 then fc = "GFC"
			elseif self.sicks > 0 then fc = "SFC"
			else fc = "FC" end
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

	self.scoreTxt.content = self.scoreFormat:gsub("%%(%w+)", vars)
	self.scoreTxt:updateHitbox()

	local event = self.scripts:event('onPopUpScore', Events.PopUpScore())
	if not event.cancelled then
		self.judgement.ratingVisible = not event.hideRating
		self.judgement.comboSprVisible = not event.hideCombo
		self.judgement.comboNumVisible = not event.hideScore
		self.judgement:spawn(rating, self.combo)
	end
end

function PlayState:loadStageWithSongName(songName)
	local curStage = PlayState.SONG.stage
	if PlayState.SONG.stage == nil then
		if songName == 'test' then
			curStage = 'test'
		elseif songName == 'spookeez' or songName == 'south' or songName ==
			'monster' then
			curStage = 'spooky'
		elseif songName == 'pico' or songName == 'philly-nice' or songName ==
			'blammed' then
			curStage = 'philly'
		elseif songName == 'satin-panties' or songName == 'high' or songName ==
			'milf' then
			curStage = 'limo'
		elseif songName == 'cocoa' or songName == 'eggnog' then
			curStage = 'mall'
		elseif songName == 'winter-horrorland' then
			curStage = 'mall-evil'
		elseif songName == "senpai" or songName == "roses" then
			curStage = "school"
		elseif songName == "thorns" then
			curStage = "school-evil"
		elseif songName == "ugh" or songName == "guns" or songName == "stress" then
			curStage = "tank"
		else
			curStage = "stage"
		end
	end
	if songName == "senpai" or songName == "roses" or songName == "thorns" then
		PlayState.pixelStage = true
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

function PlayState:leave()
	self.scripts:call("leave")

	PlayState.conductor = nil
	Timer.setSpeed(1)

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	self.scripts:call("postLeave")
end

return PlayState
