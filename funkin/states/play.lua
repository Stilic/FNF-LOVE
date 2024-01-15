local PauseSubstate = require "funkin.substates.pause"

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

	if data then
		PlayState.SONG = data.song
	else
		local metadata = paths.getJSON('songs/' .. song .. '/meta')
		PlayState.SONG = {
			song = song,
			bpm = metadata.bpm or 150,
			speed = 1,
			needsVoices = true,
			stage = 'stage',
			player1 = 'bf',
			player2 = 'dad',
			gfVersion = 'gf',
			notes = {}
		}
	end
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
		PlayState.loadSong(song, diff)
	end
end

function PlayState:enter()
	if PlayState.SONG == nil then PlayState.loadSong("test") end
	local songName = paths.formatToSongPath(PlayState.SONG.song)

	PlayState.conductor = Conductor():setSong(PlayState.SONG)
	PlayState.conductor.onStep = function(s) self:step(s) end
	PlayState.conductor.onBeat = function(b) self:beat(b) end
	PlayState.conductor.onSection = function(s) self:section(s) end

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts")
	self.scripts:loadDirectory("data/scripts/" .. songName)
	self.scripts:loadDirectory("songs/" .. songName)
	self.scripts:call("create")

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
	PlayState.SONG.stage = curStage

	-- reset ui stage
	PlayState.pixelStage = false

	self.stage = Stage(PlayState.SONG.stage)
	self:add(self.stage)
	table.insert(self.scripts.scripts, self.stage.script)

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
	self.camOther = Camera()
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camOther, false)

	self.receptors = Group()
	self.playerReceptors = Group()
	self.enemyReceptors = Group()

	local rx, ry = game.width / 2, 50
	if self.downScroll then ry = game.height - 100 - ry end
	for i = 0, 1 do
		for j = 0, 3 do
			local rep = Receptor(rx + (game.width / 4) * (i == 1 and 1 or -1),
				ry, j, i)
			rep:groupInit()
			self.receptors:add(rep)
			if i == 1 then
				if self.middleScroll then rep.x = rep.x - 318 end
				self.playerReceptors:add(rep)
			else
				if self.middleScroll then rep.visible = false end
				self.enemyReceptors:add(rep)
			end
		end
	end

	self.splashes = Group()

	local splash = NoteSplash()
	splash.alpha = 0
	self.splashes:add(splash)

	self.judgeSprites = Group()

	local gfVersion = PlayState.SONG.gfVersion
	if gfVersion == nil then
		switch(curStage, {
			["limo"] = function() gfVersion = "gf-car" end,
			["mall"] = function() gfVersion = "gf-christmas" end,
			["mall-evil"] = function() gfVersion = "gf-christmas" end,
			["school"] = function() gfVersion = "gf-pixel" end,
			["school-evil"] = function() gfVersion = "gf-pixel" end,
			["tank"] = function()
				if songName == 'stress' then
					gfVersion = "pico-speaker"
				else
					gfVersion = "gf-tankmen"
				end
			end,
			default = function() gfVersion = "gf" end
		})
		PlayState.SONG.gfVersion = gfVersion
	end

	self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
		self.SONG.gfVersion, false)
	self.gf:setScrollFactor(0.95, 0.95)
	table.insert(self.scripts.scripts, self.gf.script)

	self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y,
		self.SONG.player2, false)
	table.insert(self.scripts.scripts, self.dad.script)

	self.boyfriend = Character(self.stage.boyfriendPos.x,
		self.stage.boyfriendPos.y, self.SONG.player1,
		true)
	table.insert(self.scripts.scripts, self.boyfriend.script)

	self:add(self.gf)
	self:add(self.dad)
	self:add(self.boyfriend)

	if self.SONG.player2:startsWith('gf') then
		self.gf.visible = false
		self.dad:setPosition(self.gf.x, self.gf.y)
	end

	self:add(self.stage.foreground)
	self:add(self.judgeSprites)

	self.camFollow = {x = 0, y = 0}
	self:cameraMovement()

	if PlayState.prevCamFollow ~= nil then
		game.camera.target = PlayState.prevCamFollow
		PlayState.prevCamFollow = nil
	else
		game.camera.target = {x = self.camFollow.x, y = self.camFollow.y}
	end

	self.camZooming = false
	game.camera.zoom = self.stage.camZoom

	self.healthBarBG = Sprite()
	self.healthBarBG:loadTexture(paths.getImage("skins/normal/healthBar"))
	self.healthBarBG:updateHitbox()
	self.healthBarBG:screenCenter("x")
	self.healthBarBG.y =
		(self.downScroll and game.height * 0.08 or game.height * 0.9)
	self.healthBarBG:setScrollFactor()

	self.healthBar = Bar(self.healthBarBG.x + 4, self.healthBarBG.y + 4,
		math.floor(self.healthBarBG.width - 8),
		math.floor(self.healthBarBG.height - 8), 0, 2, true)
	self.healthBar:setValue(self.health)

	self.iconP1 = HealthIcon(self.boyfriend.icon, true)
	self.iconP1.y = self.healthBar.y - 75

	self.iconP2 = HealthIcon(self.dad.icon, false)
	self.iconP2.y = self.healthBar.y - 75

	local textOffset = 36
	if self.downScroll then textOffset = -textOffset end

	local fontScore = paths.getFont("vcr.ttf", 17)
	self.scoreTxt = Text(0, self.healthBarBG.y + textOffset, "", fontScore,
		{1, 1, 1}, "center")
	self.scoreTxt.outline.width = 1
	self.scoreTxt.antialiasing = false

	self.timeArcBG = Graphic(45, game.height - 45, 100, 100, {0, 0, 0}, "arc",
		"line")
	if self.downScroll then self.timeArcBG.y = 45 end
	self.timeArcBG.line.width = 18
	self.timeArcBG.config = {
		radius = 24,
		type = "closed",
		angle = {0, 360},
		segments = 40
	}
	self.timeArcBG:updateDimensions()

	self.timeArc = Graphic(self.timeArcBG.x, self.timeArcBG.y, 100, 100,
		{1, 1, 1}, "arc", "line")
	self.timeArc.line.width = 10
	self.timeArc.config = {
		radius = 24,
		type = "open",
		angle = {-90, 0},
		segments = 40
	}
	self.timeArc:updateDimensions()

	local fontTime = paths.getFont("vcr.ttf", 24)
	self.timeTxt = Text(self.timeArcBG.x + 35, self.timeArcBG.y + 7, "",
		fontTime, {1, 1, 1}, "left")
	self.timeTxt.outline.width = 2
	self.timeTxt.antialiasing = false
	if self.downScroll then self.timeTxt.y = self.timeArcBG.y - 32 end

	self.botplayTxt = Text(620, (self.downScroll and 8 or 688), 'BOTPLAY MODE',
		fontTime, {1, 1, 1}, "right", game.width / 2)
	self.botplayTxt.outline.width = 2
	self.botplayTxt.antialiasing = false
	self.botplayTxt.visible = self.botPlay

	if love.system.getDevice() == "Mobile" then
		local width = game.width / 4

		self.buttons = ButtonGroup()

		self.buttons.width = width
		self.buttons.height = game.height
		self.buttons.cameras = {self.camOther}
		self.buttons.fill = "line"
		self.buttons.visible = false

		local bl = Button(0, 0, 0, 0, "left", {1, 0, 1})
		local bd = Button(width, 0, 0, 0, "down", Color.BLUE)
		local bu = Button(width * 2, 0, 0, 0, "up", Color.GREEN)
		local br = Button(width * 3, 0, 0, 0, "right", Color.RED)

		self.buttons:add(bl)
		self.buttons:add(bd)
		self.buttons:add(bu)
		self.buttons:add(br)
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
	self:add(self.timeArcBG)
	self:add(self.timeArc)
	self:add(self.timeTxt)
	self:add(self.botplayTxt)

	if love.system.getDevice() == "Mobile" then self:add(self.buttons) end

	self:recalculateRating()

	for _, o in ipairs({
		self.receptors, self.splashes, self.notesGroup, self.sustainsGroup,
		self.healthBarBG, self.healthBar, self.iconP1, self.iconP2,
		self.scoreTxt, self.timeArcBG, self.timeArc, self.timeTxt, self.botplayTxt
	}) do o.cameras = {self.camHUD} end

	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = function(...) self:onKeyPress(...) end
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = function(...) self:onKeyRelease(...) end
	controls:bindRelease(self.bindedKeyRelease)

	self.startingSong = true

	self.countdownTimer = Timer.new()
	self.startedCountdown = false

	if self.storyMode and not PlayState.seenCutscene then
		PlayState.seenCutscene = true

		local fileExist = paths.exists(paths.getMods('data/cutscenes/' .. songName .. '.lua'), 'file') or
			paths.exists(paths.getPath('data/cutscenes/' .. songName .. '.lua'), 'file')
		if fileExist then
			local cutsceneScript = Script('data/cutscenes/' .. songName)

			cutsceneScript:call("create")
			table.insert(self.scripts.scripts, cutsceneScript)
		else
			self:startCountdown()
		end
	else
		self:startCountdown()
	end

	if love.system.getDevice() == 'Desktop' then
		local detailsText = "Freeplay"
		if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

		local diff = PlayState.defaultDifficulty
		if PlayState.songDifficulty ~= "" then
			diff = PlayState.songDifficulty:gsub("^%l", string.upper)
		end

		Discord.changePresence({
			details = detailsText,
			state = self.SONG.song .. ' - [' .. diff .. ']'
		})
	end

	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	self.scripts:call("postCreate")
end

function PlayState:startCountdown()
	if love.system.getDevice() == "Mobile" then
		self.buttons.visible = true
		game.buttons.add(self.buttons)
	end
	self:section(0)

	local event = self.scripts:call("startCountdown")
	if not event.cancelled then
		self.startedCountdown = true

		local basePath = "skins/" .. (PlayState.pixelStage and "pixel" or "normal")
		local countdownData = {
			{sound = basePath .. "/intro3",  image = nil},
			{sound = basePath .. "/intro2",  image = basePath .. "/ready"},
			{sound = basePath .. "/intro1",  image = basePath .. "/set"},
			{sound = basePath .. "/introGo", image = basePath .. "/go"}
		}

		local crotchet = PlayState.conductor.crotchet / 1000
		for swagCounter = 0, 4 do
			self.countdownTimer:after(crotchet * (swagCounter + 1), function()
				local data = countdownData[swagCounter + 1]
				if data then
					if data.sound then
						game.sound.play(paths.getSound(data.sound))
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

				self:beat(swagCounter - 4)
			end)
		end
	end
end

local function fadeGroupSprites(obj)
	if obj then
		if obj:is(Group) then
			for _, o in ipairs(obj.members) do fadeGroupSprites(o) end
		elseif obj.alpha then
			return Timer.tween(2, obj, {alpha = 0}, 'in-out-sine')
		end
	end
	return false
end

function PlayState:update(dt)
	self.lastTick = love.timer.getTime()

	self.scripts:call("update", dt)

	self.countdownTimer:update(dt)

	if self.startedCountdown then
		PlayState.conductor.time = PlayState.conductor.time + dt * 1000 * game.sound.music:getActualPitch()
		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false
			game.sound.music:seek(self.startPos / 1000)
			game.sound.music:play()
			if self.vocals then
				self.vocals:seek(game.sound.music:tell())
				self.vocals:play()
			end
			self.scripts:call("songStart")

			if not self.startingSong and love.system.getDevice() == "Desktop" then
				local detailsText = "Freeplay"
				if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

				local startTimestamp = os.time(os.date("*t"))
				local endTimestamp = startTimestamp +
					game.sound.music:getDuration()

				local diff = PlayState.defaultDifficulty
				if PlayState.songDifficulty ~= "" then
					diff = PlayState.songDifficulty:gsub("^%l", string.upper)
				end

				Discord.changePresence({
					details = detailsText,
					state = self.SONG.song .. ' - [' .. diff .. ']',
					startTimestamp = math.floor(startTimestamp),
					endTimestamp = math.floor(endTimestamp)
				})
			end
		end
	end

	PlayState.notePosition = PlayState.conductor.time

	PlayState.conductor:update()
	PlayState.super.update(self, dt)

	game.camera.target.x, game.camera.target.y =
		util.coolLerp(game.camera.target.x, self.camFollow.x, 2.4 * self.stage.camSpeed, dt),
		util.coolLerp(game.camera.target.y, self.camFollow.y, 2.4 * self.stage.camSpeed, dt)

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

	self.timeTxt.content = util.getFormattedTime(songTime)

	self.timeArc.x = self.timeArcBG.x
	local timeAngle = ((PlayState.conductor.time / 1000) /
			(game.sound.music:getDuration() / 1000)) *
		0.36
	self.timeArc.config.angle[2] = -90 + math.ceil(timeAngle)

	if self.camZooming then
		game.camera.zoom = util.coolLerp(game.camera.zoom, self.stage.camZoom, 3, dt)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt)
	end

	if self.startedCountdown then
		local PAUSE_PRESSED = controls:pressed("pause")
		if love.system.getDevice() == "Mobile" then
			PAUSE_PRESSED = Keyboard.justPressed.ESCAPE
		end
		if PAUSE_PRESSED then
			local event = self.scripts:call("paused")
			if not event.cancelled then
				game.sound.music:pause()
				if self.vocals then self.vocals:pause() end

				self.paused = true

				if love.system.getDevice() == 'Desktop' then
					local detailsText = "Freeplay"
					if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

					local diff = PlayState.defaultDifficulty
					if PlayState.songDifficulty ~= "" then
						diff = PlayState.songDifficulty:gsub("^%l", string.upper)
					end

					Discord.changePresence({
						details = "Paused - " .. detailsText,
						state = self.SONG.song .. ' - [' .. diff .. ']'
					})
				end

				if love.system.getDevice() == "Mobile" then
					self.buttons.visible = false
					game.buttons.remove(self.buttons)
				end

				local pause = PauseSubstate()
				pause.cameras = {self.camOther}
				self:openSubstate(pause)
			end
		end
		if controls:pressed("debug_1") then
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			game.switchState(ChartingState())
		end
		if controls:pressed("debug_2") then
			game.sound.music:pause()
			if self.vocals then self.vocals:pause() end
			CharacterEditor.onPlayState = true
			game.switchState(CharacterEditor())
		end
		if controls:pressed("reset") then self.health = 0 end
	end

	if self.health <= 0 and not self.isDead then
		self.paused = true

		game.sound.music:pause()
		if self.vocals then self.vocals:pause() end

		if love.system.getDevice() == 'Desktop' then
			local detailsText = "Freeplay"
			if self.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

			local diff = PlayState.defaultDifficulty
			if PlayState.songDifficulty ~= "" then
				diff = PlayState.songDifficulty:gsub("^%l", string.upper)
			end

			Discord.changePresence({
				details = "Game Over - " .. detailsText,
				state = self.SONG.song .. ' - [' .. diff .. ']'
			})
		end

		fadeGroupSprites(self.stage)
		fadeGroupSprites(self.gf)
		fadeGroupSprites(self.dad)
		fadeGroupSprites(self.stage.foreground)

		self.camHUD.visible = false
		self.boyfriend.visible = false

		if love.system.getDevice() == "Mobile" then
			self.buttons.visible = false
			game.buttons.remove(self.buttons)
		end

		self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x,
			self.stage.boyfriendPos.y))
		self.isDead = true
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
				if self.vocals then self.vocals:setVolume(0) end

				if self.combo > 0 then self.combo = 0 end
				self.combo = self.combo - 1
				self.score = self.score - 100
				self.misses = self.misses + 1

				self.totalPlayed = self.totalPlayed + 1
				self:recalculateRating()

				local np = n.isSustain and n.parentNote or n
				np.tooLate = true
				for _, no in ipairs(np.children) do
					no.tooLate = true
				end

				if self.health < 0 then self.health = 0 end

				self.health = self.health - 0.0475
				self.healthBar:setValue(self.health)

				self.boyfriend:sing(n.data, "miss")

				if self.gf.__animations['sad'] then
					self.gf:playAnim('sad', true)
					self.gf.lastHit = PlayState.conductor.time
				end
				self:popUpScore()
			end

			self:removeNote(n)
		end
	end

	if Project.DEBUG_MODE then
		if Keyboard.justPressed.TWO then self:endSong() end
		if Keyboard.justPressed.ONE then self.botPlay = not self.botPlay end
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
	if section ~= nil then
		if section.gfSection then
			local x, y = self.gf:getMidpoint()
			self.camFollow.x = x -
				(self.gf.cameraPosition.x -
					self.stage.gfCam.x)
			self.camFollow.y = y -
				(self.gf.cameraPosition.y -
					self.stage.gfCam.y)
		else
			if section.mustHitSection then
				local x, y = self.boyfriend:getMidpoint()
				self.camFollow.x = x - 100 -
					(self.boyfriend.cameraPosition.x -
						self.stage.boyfriendCam.x)
				self.camFollow.y = y - 100 +
					(self.boyfriend.cameraPosition.y +
						self.stage.boyfriendCam.y)
			else
				local x, y = self.dad:getMidpoint()
				self.camFollow.x = x + 150 +
					(self.dad.cameraPosition.x +
						self.stage.dadCam.x)
				self.camFollow.y = y - 100 +
					(self.dad.cameraPosition.y +
						self.stage.dadCam.y)
			end
		end
	end

	if paths.formatToSongPath(self.SONG.song) == 'tutorial' then
		if section.mustHitSection then
			Timer.tween((self.conductor.stepCrotchet * 4 / 1000),
				game.camera, {zoom = 1}, 'in-out-elastic')
		else
			Timer.tween((self.conductor.stepCrotchet * 4 / 1000),
				game.camera, {zoom = 1.3}, 'in-out-elastic')
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
		if self.vocals and not self.startingSong then
			self.vocals:seek(game.sound.music:tell())
		end
		game.sound.music:play()
		if self.vocals then self.vocals:play() end

		if love.system.getDevice() == 'Desktop' then
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
				state = self.SONG.song .. ' - [' .. diff .. ']',
				startTimestamp = math.floor(startTimestamp),
				endTimestamp = math.floor(endTimestamp)
			})
		end

		if love.system.getDevice() == "Mobile" then
			self.buttons.visible = true
			game.buttons.add(self.buttons)
		end
	end
end

function PlayState:onSettingChange(setting)
	if setting == 'gameplay' then
		self.botPlay = ClientPrefs.data.botplayMode
		self.downScroll = ClientPrefs.data.downScroll
		self.middleScroll = ClientPrefs.data.middleScroll

		local songTime = PlayState.conductor.time / 1000
		if ClientPrefs.data.timeType == "left" then
			songTime = game.sound.music:getDuration() - songTime
		end
		self.timeTxt.content = util.getFormattedTime(songTime)

		self.botplayTxt.visible = self.botPlay
		self.botplayTxt.y = self.downScroll and 8 or 688

		local rx, ry = game.width / 2, 50
		if self.downScroll then ry = game.height - 100 - ry end
		for _, rep in ipairs(self.receptors.members) do
			rep:setPosition(rx + (game.width / 4) * (rep.player == 1 and 1 or -1), ry)
			rep:groupInit()
			rep.visible = true
			if self.middleScroll then
				if rep.player == 1 then
					rep.x = rep.x - 318
				else
					rep.visible = false
				end
			end
		end

		self.healthBarBG.y = self.downScroll and game.height * 0.08 or game.height * 0.9
		self.healthBar.y = self.healthBarBG.y + 4

		self.iconP1.y = self.healthBar.y - 75
		self.iconP2.y = self.healthBar.y - 75

		local textOffset = 36
		if self.downScroll then textOffset = -textOffset end
		self.scoreTxt.y = self.healthBarBG.y + textOffset

		self.timeArcBG.y = self.downScroll and 45 or game.height - 45
		self.timeArc.y = self.timeArcBG.y
		self.timeTxt.y = self.downScroll and self.timeArcBG.y - 32 or self.timeArcBG.y + 7

		local n
		for i = 1, #self.unspawnNotes do
			n = self.unspawnNotes[i]
			n.visible = not self.middleScroll or n.mustPress
		end

		for i = 1, #self.allNotes.members do
			n = self.allNotes.members[i]
			n.visible = not self.middleScroll or n.mustPress
		end

		self:updateNotes()
	elseif setting == 'controls' then
		controls:unbindPress(self.bindedKeyPress)
		controls:unbindRelease(self.bindedKeyRelease)

		self.bindedKeyPress = function(...) self:onKeyPress(...) end
		controls:bindPress(self.bindedKeyPress)

		self.bindedKeyRelease = function(...) self:onKeyRelease(...) end
		controls:bindRelease(self.bindedKeyRelease)
	end

	self.scripts:call("onSettingChange", setting)
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

function PlayState:goodNoteHit(n)
	if not n.wasGoodHit then
		n.wasGoodHit = true
		self.scripts:call("goodNoteHit", n)

		if self.vocals then self.vocals:setVolume(1) end

		local animType = ''
		if PlayState.SONG.notes[PlayState.conductor.currentSection + 1].altAnim then
			animType = 'alt'
		end

		local char = (n.mustPress and self.boyfriend or self.dad)
		char:sing(n.data, animType)

		if paths.formatToSongPath(self.SONG.song) ~= 'tutorial' then
			if not n.mustPress then self.camZooming = true end
		end

		local time = 0
		if not n.mustPress or self.botPlay then
			time = 0.15
			if n.isSustain and not n.isSustainEnd then
				time = time * 2
			end
		end
		local receptor = (n.mustPress and self.playerReceptors or
			self.enemyReceptors).members[n.data + 1]
		receptor:confirm(time)

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

					if self.health > 2 then self.health = 2 end

					self.health = self.health + 0.023
					self.healthBar:setValue(self.health)
				end

				if ClientPrefs.data.noteSplash and rating.splash then
					local splash = self.splashes:recycle(NoteSplash)
					splash.x, splash.y = receptor.x, receptor.y
					splash:setup(n.data)
				end
				self:popUpScore(rating.name)

				self.totalHit = self.totalHit + rating.mod
				self.totalPlayed = self.totalPlayed + 1
				self:recalculateRating(rating.name)
			end

			self:removeNote(n)
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
		local fileExist = (paths.exists(paths.getMods('data/cutscenes/' .. songName .. '-end.lua'), 'file') or
			paths.exists(paths.getPath('data/cutscenes/' .. songName .. '-end.lua'), 'file'))
		if fileExist then
			local cutsceneScript = Script('data/cutscenes/' .. songName .. '-end')
			cutsceneScript:call("create")
			table.insert(self.scripts.scripts, cutsceneScript)
			cutsceneScript:call("postCreate")
			return
		else
			self:endSong(true)
			return
		end
	end

	local event = self.scripts:call("endSong")

	if not event.cancelled then
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
				game.sound.playMusic(paths.getMusic("freakyMenu"))
			end
		else
			game.switchState(FreeplayState())
			game.sound.playMusic(paths.getMusic("freakyMenu"))
		end
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
	end
	self.scripts:set("curStep", s)
	self.scripts:call("step")
	self.scripts:call("postStep")
end

function PlayState:beat(b)
	if not self.startingSong then
		self.scripts:set("curBeat", b)
		self.scripts:call("beat")

		local scaleNum = 1.2
		self.iconP1.scale = {x = scaleNum, y = scaleNum}
		self.iconP2.scale = {x = scaleNum, y = scaleNum}
	end

	self.boyfriend:beat(b)
	self.gf:beat(b)
	self.dad:beat(b)

	if not self.startingSong then
		self.scripts:call("postBeat")
	end
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

	self:cameraMovement()

	self.scripts:call("postSection")
end

function PlayState:popUpScore(rating)
	local accel = PlayState.conductor.crotchet * 0.001

	local judgeSpr = self.judgeSprites:recycle()

	local antialias = not PlayState.pixelStage
	local uiStage = PlayState.pixelStage and "pixel" or "normal"

	if rating == nil then rating = "shit" end
	judgeSpr:loadTexture(paths.getImage("skins/" .. uiStage .. "/" ..
		rating))
	judgeSpr.alpha = 1
	judgeSpr:setGraphicSize(math.floor(judgeSpr.width *
		(PlayState.pixelStage and 4.7 or 0.7)))
	judgeSpr:updateHitbox()
	judgeSpr:screenCenter()
	judgeSpr.moves = true
	-- use fixed values to display at the same position on a different resolution
	judgeSpr.x = (1280 - judgeSpr.width) * 0.5 + 190
	judgeSpr.y = (720 - judgeSpr.height) * 0.5 - 60
	judgeSpr.velocity.x = 0
	judgeSpr.velocity.y = 0
	judgeSpr.alpha = 1
	if self.combo <= 0 then judgeSpr.alpha = 0 end
	judgeSpr.antialiasing = antialias

	judgeSpr.acceleration.y = 550
	judgeSpr.velocity.y = judgeSpr.velocity.y - math.random(140, 175)
	judgeSpr.velocity.x = judgeSpr.velocity.x - math.random(0, 10)

	Timer.after(accel, function()
		Timer.tween(0.2, judgeSpr, {alpha = 0}, "linear", function()
			Timer.cancelTweensOf(judgeSpr)
			judgeSpr:kill()
		end)
	end)

	local lastSpr
	local coolX, comboStr = 1280 * 0.55, string.format("%03d", self.combo)
	if self.combo < 0 then comboStr = string.format("-%03d", math.abs(self.combo)) end
	for i = 1, #comboStr do
		if self.combo >= 10 or self.combo <= 0 then
			local digit = tostring(comboStr:sub(i, i)) or ""

			if digit == "-" then digit = "negative" end

			local numScore = self.judgeSprites:recycle()
			numScore:loadTexture(paths.getImage(
				"skins/" .. uiStage .. "/num" .. digit))
			numScore:setGraphicSize(math.floor(numScore.width *
				(PlayState.pixelStage and 4.5 or
					0.5)))
			numScore:updateHitbox()
			numScore.moves = true
			numScore.x = (lastSpr and lastSpr.x or coolX - 90) + numScore.width
			numScore.y = judgeSpr.y + 115
			numScore.velocity.y = 0
			numScore.velocity.x = 0
			numScore.alpha = 1
			numScore.antialiasing = antialias

			numScore.acceleration.y = math.random(200, 300)
			numScore.velocity.y = numScore.velocity.y - math.random(140, 160)
			numScore.velocity.x = math.random(-5.0, 5.0)

			Timer.after(accel * 2, function()
				Timer.tween(0.2, numScore, {alpha = 0}, "linear", function()
					Timer.cancelTweensOf(numScore)
					numScore:kill()
				end)
			end)

			lastSpr = numScore
		end
	end
end

function PlayState:focus(f)
	if love.system.getDevice() == 'Desktop' then
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
				state = self.SONG.song .. ' - [' .. diff .. ']',
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
				state = self.SONG.song .. ' - [' .. diff .. ']'
			})
		end
	end
end

function PlayState:recalculateRating(rating)
	if self.totalPlayed > 0 then
		self.accuracy = math.min(1, math.max(0, self.totalHit / self.totalPlayed))
	end

	local ratingStr = (self.totalPlayed > 0 and "({fc}) {r}" or "?")

	if rating then
		local category = rating .. "s"
		if self[category] then
			self[category] = self[category] + 1
		end
	end

	local class = ""
	if self.accuracy >= 0.995 then
		class = "S+"
	elseif self.accuracy >= 0.960 then
		class = "S"
	elseif self.accuracy >= 0.905 then
		class = "A"
	elseif self.accuracy >= 0.850 then
		class = "B"
	elseif self.accuracy >= 0.795 then
		class = "C"
	elseif self.accuracy >= 0.745 then
		class = "D"
	elseif self.accuracy < 0.750 then
		class = "E"
	end

	local FC = ""
	if self.misses < 1 then
		if self.sicks > 0 and self.goods < 1 and self.bads < 1 and self.shits < 1 then
			FC = "SFC"
		elseif self.goods > 0 and self.bads < 1 and self.shits < 1 then
			FC = "GFC"
		elseif self.bads > 0 or self.shits > 0 then
			FC = "FC"
		end
	else
		FC = "SDCB"
		if self.misses >= 10 then
			FC = "Clear"
		end
	end
	self.rating = ratingStr:gsub("{fc}", FC):gsub("{r}", class)

	self.scoreTxt.content = "Score: " .. self.score ..
		" // Combo Breaks: " .. self.misses ..
		" // " .. math.truncate(self.accuracy * 100, 2) ..
		"% - " .. self.rating

	self.scoreTxt:screenCenter("x")
end

function PlayState:leave()
	self.scripts:call("leave")

	PlayState.conductor = nil

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	self.scripts:call("postLeave")
end

return PlayState
