local Events = require "funkin.backend.scripting.events"
local PauseSubstate = require "funkin.substates.pause"

--[[ LIST TODO OR NOTES
	maybe make scripts vars just include conductor itself instead of the properties of conductor
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
PlayState.ratings = {
	{name = "sick", time = 45,        score = 350, splash = true,  mod = 1},
	{name = "good", time = 90,        score = 200, splash = false, mod = 0.7},
	{name = "bad",  time = 135,       score = 100, splash = false, mod = 0.4},
	{name = "shit", time = math.huge, score = 50,  splash = false, mod = 0.2}
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
	if PlayState.SONG == nil then PlayState.loadSong('fresh') end
	local songName = paths.formatToSongPath(PlayState.SONG.song)

	local conductor = Conductor():setSong(PlayState.SONG)
	conductor.time = self.startPos - (conductor.crotchet * 5)
	conductor.onStep = bind(self, self.step)
	conductor.onBeat = bind(self, self.beat)
	conductor.onSection = bind(self, self.section)
	PlayState.conductor = conductor

	self.scoreFormat = "Score: %score // Combo Breaks: %misses // %accuracy% - %rating"
	self.scoreFormatVariables = {score = 0, misses = 0, accuracy = 0, rating = 0}

	self.timer = Timer.new()

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts", "data/scripts/" .. songName, "songs/" .. songName)

	self.scripts:set("bpm", PlayState.conductor.bpm)
	self.scripts:set("crotchet", PlayState.conductor.crotchet)
	self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)

	self.scripts:call("create")

	self.startingSong = true
	self.startedCountdown = false
	self.doCountdownAtBeats = nil

	self.playback = 1
	Timer.setSpeed(1)

	self.camNotes = Camera()
	self.camHUD = Camera()
	self.camOther = Camera()
	game.cameras.add(self.camNotes, false)
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camOther, false)

	self.camNotes.bgColor[4] = ClientPrefs.data.backgroundDim / 100

	if game.sound.music then game.sound.music:reset(true) end
	game.sound.loadMusic(paths.getInst(songName))
	game.sound.music:setLooping(false)
	game.sound.music.onComplete = function() self:endSong() end

	if PlayState.SONG.needsVoices then
		self.vocals = Sound():load(paths.getVoices(songName))
		game.sound.list:add(self.vocals)
	end

	self.isDead = false
	GameOverSubstate.resetVars()

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
	game.camera.zoom = self.stage.camZoom
	self.camZooming = false

	self.notefields = {Notefield(), Notefield()}
	self.playerNotefield, self.enemyNotefield = unpack(self.notefields)
	self.playerNotefield.cameras = {self.camNotes}
	self.enemyNotefield.cameras = {self.camNotes}
	self:generateNotes()

	self:add(self.playerNotefield)
	self:add(self.enemyNotefield)

	self.countdown = Countdown()
	self.countdown:screenCenter()
	self:add(self.countdown)

	self.botplayTxt = Text(604, game.height - 200, 'BOTPLAY MODE',
		fontTime, {1, 1, 1}, "right", game.width / 2)
	self.botplayTxt.outline.width = 2
	self.botplayTxt.antialiasing = false
	self.botplayTxt.visible = self.botPlay
	self:add(self.botplayTxt)

	for _, o in ipairs({
		self.botplayTxt, self.countdown
	}) do o.cameras = {self.camHUD} end

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

	if self.buttons then self:add(self.buttons) end

	self.keysPressed = {}
	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = bind(self, self.onKeyPress)
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = bind(self, self.onKeyRelease)
	controls:bindRelease(self.bindedKeyRelease)

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

	PlayState.super.enter(self)
	collectgarbage()

	self.scripts:call("postCreate")	
end

function PlayState:generateNotes()

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
	self.doCountdownAtBeats = -4
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

	game.camera:follow(self.camFollow, nil, 2.4 * self.stage.camSpeed)
end

-- this function is fatal, that i mean its using alot of processing times!!!
function PlayState:cameraMovement(s)
	local section = PlayState.SONG.notes[math.max((s or PlayState.conductor.currentSection + 1), 1)]
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
	self.scripts:set("curStep", s)
	self.scripts:call("step")
	self.scripts:call("postStep")
end

function PlayState:beat(b)
	self.scripts:set("curBeat", b)
	self.scripts:call("beat")

	if self.doCountdownAtBeats then
		local beat = b - self.doCountdownAtBeats + 1
		self.countdown:doCountdown(beat)

		if beat >= #self.countdown.data then
			self.doCountdownAtBeats = nil
		end
	end

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

	if self.startedCountdown then
		self:cameraMovement(s + 1)
	end

	if self.camZooming and game.camera.zoom < 1.35 then
		game.camera.zoom = game.camera.zoom + 0.015
		self.camHUD.zoom = self.camHUD.zoom + 0.03
	end

	self.scripts:call("postSection")
end

function PlayState:update(dt)
	dt = dt * self.playback
	self.lastTick = love.timer.getTime()
	self.scripts:call("update", dt)
	self.timer:update(dt)

	if self.startedCountdown then
		PlayState.conductor.time = PlayState.conductor.time + dt * 1000
		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.camZooming = true
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

			PlayState.conductor.time = game.sound.music:tell()

			self.scripts:call("songStart")
		elseif game.sound.music:isPlaying() then
			local rate = math.max(self.playback, 1)
			local time = game.sound.music:tell()
			if self.vocals and self.vocals:isPlaying()
				and PlayState.conductor.lastStep ~= PlayState.conductor.currentStep
				and math.abs(time - self.vocals:tell()) > 0.015 * rate
			then
				self.vocals:seek(time)
			end

			local contime = PlayState.conductor.time / 1000
			if math.abs(time - contime) > 0.015 * rate then
				PlayState.conductor.time = util.coolLerp(math.clamp(contime, time - rate, time + rate), time, 14, dt) * 1000
			end
		end

		PlayState.conductor:update()
	end

	PlayState.super.update(self, dt)

	if self.camZooming then
		game.camera.zoom = util.coolLerp(game.camera.zoom, self.stage.camZoom, 3, dt)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt)
	end

	if self.startedCountdown then
		if (self.buttons and game.keys.justPressed.ESCAPE) or controls:pressed("pause") then
			self:tryPause()
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

		if controls:pressed("reset") then
			self.health = 0
		end
	end

	if self.health <= 0 and not self.isDead then
		self:tryGameOver()
	end

	if Project.DEBUG_MODE then
		if game.keys.justPressed.TWO then self:endSong() end
		if game.keys.justPressed.ONE then self.botPlay = not self.botPlay end
	end

	self.scripts:call("postUpdate", dt)
end

function PlayState:focus(f)
	
end

function PlayState:tryPause()
	local event = self.scripts:call("paused")
	if event ~= Script.Event_Cancel then
		game.camera:unfollow()
	
		game.sound.music:pause()
		if self.vocals then self.vocals:pause() end

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

		self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x, self.stage.boyfriendPos.y))
		self.isDead = true
	end
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

	--

	PlayState.conductor.time = prev
end

function PlayState:onKeyRelease(key, type)
	if self.botPlay or (self.substate and not self.persistentUpdate) then return end
	local controls = controls:getControlsFromSource(type .. ":" .. key)

	if not controls then return end
	key = self:getKeyFromEvent(controls)

	if key < 0 then return end
	self.keysPressed[key] = false
end

function PlayState:closeSubstate()
	PlayState.super.closeSubstate(self)

	game.camera:follow(self.camFollow, nil, 2.4 * self.stage.camSpeed)
	if not self.startingSong then
		game.sound.music:play()

		if self.vocals then
			self.vocals:seek(game.sound.music:tell())
			self.vocals:play()
		end
	end

	if self.buttons then
		self.buttons:enable()
	end
end

function PlayState:draw()
	self.scripts:call("draw")
	PlayState.super.draw(self)
	self.scripts:call("postDraw")
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
	game.sound.music.onComplete = nil

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

			game.sound.music:reset(true)
			game.sound.playMusic(paths.getMusic("freakyMenu"))
		end
	else
		game.camera:unfollow()
		game.switchState(FreeplayState())

		game.sound.music:reset(true)
		game.sound.playMusic(paths.getMusic("freakyMenu"))
	end

	self.scripts:call("postEndSong")
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
