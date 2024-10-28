local Events = require "funkin.backend.scripting.events"
local PauseSubstate = require "funkin.substates.pause"
local Cutscene = require "funkin.gameplay.cutscene"
local GUI = require "funkin.gameplay.gui"

---@class PlayState:State
local PlayState = State:extend("PlayState")
PlayState.EVENTS = Events
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

PlayState:implement(require "funkin.gameplay.playbase")

function PlayState.loadSong(song, diff)
	diff = diff or PlayState.defaultDifficulty
	PlayState.songDifficulty = diff
	PlayState.SONG = API.chart.parse(song, diff)
	return true
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
	if PlayState.SONG == nil then PlayState.loadSong('test') end
	PlayState.SONG.skin = util.getSongSkin(PlayState.SONG)

	local songName = paths.formatToSongPath(PlayState.SONG.song)

	local conductor = self:setupConductorSong(PlayState.SONG)
	conductor.time = self.startPos - conductor.crotchet * 5
	PlayState.conductor = conductor

	self.skipConductor = false

	Note.defaultSustainSegments = 3
	NoteModifier.reset()

	self.timer = Timer.newManager()
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

	self.startedCountdown = false
	self.doCountdownAtBeats = nil
	self.lastCountdownBeats = nil

	self.isDead = false
	GameOverSubstate.resetVars()

	self.usedBotPlay = ClientPrefs.data.botplayMode
	self.downScroll = ClientPrefs.data.downScroll
	self.middleScroll = ClientPrefs.data.middleScroll

	self.playback = 1

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

	self.stage = Stage(PlayState.SONG.stage)
	self:add(self.stage)
	self.scripts:add(self.stage.script)

	if PlayState.SONG.gfVersion ~= "" then
		self.gf = Character(self.stage.gfPos.x, self.stage.gfPos.y,
			PlayState.SONG.gfVersion, false)
		self.gf:setScrollFactor(0.95, 0.95)
		self:add(self.gf)
		self.scripts:add(self.gf.script)
	end

	if PlayState.SONG.player2 ~= "" then
		self.dad = Character(self.stage.dadPos.x, self.stage.dadPos.y,
			PlayState.SONG.player2, false)
		self:add(self.dad)
		self.scripts:add(self.dad.script)
	end

	if PlayState.SONG.player1 ~= "" then
		self.boyfriend = Character(self.stage.boyfriendPos.x,
			self.stage.boyfriendPos.y, PlayState.SONG.player1,
			true)
		self.boyfriend.waitReleaseAfterSing = not ClientPrefs.data.botplayMode
		self:add(self.boyfriend)
		self.scripts:add(self.boyfriend.script)
	end

	if self.gf and PlayState.SONG.player2:startsWith("gf") then
		self.gf.visible = false
		self.dad:setPosition(self.gf.x, self.gf.y)
	end

	self:add(self.stage.foreground)

	game.camera.zoom, self.camZoom, self.camZooming,
	self.camZoomSpeed, self.camSpeed, self.camTarget =
		self.stage.camZoom, self.stage.camZoom, true,
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

	self:generateNotefields(4, songName, self.camNotes)
	table.insert(self.notefields, {character = self.gf})

	if PlayState.canFadeInReceptors then
		for notefield in each(self.notefields) do
			if notefield.is then
				for receptor in each(notefield.receptors) do
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
	self.countdown.cameras = {self.camHUD}
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

	self.gui = GUI()
	self.gui.cameras = {self.camHUD}
	self:add(self.gui)

	self.score = 0
	self.combo = 0
	self.misses = 0
	self.health = 1

	self.ratings = {
		{name = "perfect", time = 0.026, score = 400, splash = true,  mod = 1},
		{name = "sick",    time = 0.038, score = 350, splash = true,  mod = 0.98},
		{name = "good",    time = 0.096, score = 200, splash = false, mod = 0.7},
		{name = "bad",     time = 0.138, score = 100, splash = false, mod = 0.4},
		{name = "shit",    time = -1,    score = 50,  splash = false, mod = 0.2}
	}
	for _, r in ipairs(self.ratings) do
		self[r.name .. "s"] = 0
	end

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

	if self.storyMode and not PlayState.seenCutscene then
		PlayState.seenCutscene = true

		local cutscene = Cutscene(false, function(event)
			local skipCountdown = event and event.params[1] or false
			if skipCountdown then
				self:startSong()
				if self.buttons then self:add(self.buttons) end
			else
				self:startCountdown()
			end
		end)
	else
		self:startCountdown()
	end
	self:recalculateRating()

	-- PRELOAD STUFF TO GET RID OF THE FATASS LAGS!!
	local path = "skins/" .. PlayState.SONG.skin .. "/"
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

function PlayState:startCountdown()
	if self.buttons then self:add(self.buttons) end

	local event = self.scripts:call("startCountdown")
	if event == Script.Event_Cancel then return end

	self.playback = self:setSongPlayback(ClientPrefs.data.playback)
	self.timer.timeScale = self.playback
	self.tween.timeScale = self.playback

	for notefield in each(self.notefields) do
		if notefield.is then
			if PlayState.canFadeInReceptors then
				notefield:fadeInReceptors()
			end
		end
	end
	PlayState.canFadeInReceptors = false

	self.startedCountdown = true
	self.doCountdownAtBeats = PlayState.startPos / PlayState.conductor.crotchet - 4

	self.countdown.duration = PlayState.conductor.crotchet / 1000
	self.countdown.playback = 1
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

function PlayState:cameraMovement(ox, oy, ease, time)
	local event = self.scripts:event("onCameraMove", Events.CameraMove(self.camTarget))
	local camX, camY = (ox or 0) + event.offset.x, (oy or 0) + event.offset.y
	if self.camPosTween then
		self.tween:cancel(self.camPosTween)
	end
	if ease then
		if game.camera.followLerp then
			game.camera:follow(self.camFollow, nil)
		end
		self.camPosTween =
			self.tween:tween(time, self.camFollow, {x = camX, y = camY}, ease, function()
				self.camFollow.tweening = false
			end)
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
		self:resyncVocals()

		if Discord then
			coroutine.wrap(PlayState.updateDiscordRPC)(self)
		end
	end

	self.scripts:set("curStep", s)
	self.scripts:call("step", s)
	self.gui:step(s)
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

	self.gui:beat(b)

	self.scripts:call("postBeat", b)
end

function PlayState:section(s)
	if self.skipConductor then return end

	self.scripts:set("curSection", s)
	self.scripts:call("section", s)

	if PlayState.SONG.notes[s] and PlayState.SONG.notes[s].changeBPM then
		self.scripts:set("bpm", PlayState.conductor.bpm)
		self.scripts:set("crotchet", PlayState.conductor.crotchet)
		self.scripts:set("stepCrotchet", PlayState.conductor.stepCrotchet)
	end

	if self.camZooming and game.camera.zoom < 1.35 then
		game.camera.zoom = game.camera.zoom + 0.015
		self.camHUD.zoom = self.camHUD.zoom + 0.03
	end

	self.gui:section(s)
	self.scripts:call("postSection", s)
end

function PlayState:focus(f)
	self.scripts:call("focus", f)
	if Discord and love.autoPause then self:updateDiscordRPC(not f) end
	PlayState.super.focus(self, f)
	self.scripts:call("postFocus", f)
end

function PlayState:executeEvent(event)
	for _, s in pairs(self.eventScripts) do
		if s.belongsTo == event.e then s:call("event", event) end
	end
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
	self.tween:update(dt)

	if self.startedCountdown then
		if not self.paused then PlayState.conductor.time = PlayState.conductor.time + dt * 1000 end

		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false

			-- reload playback for countdown skip
			self.playback = ClientPrefs.data.playback
			self.timer.timeScale = self.playback
			self.tween.timeScale = self.playback

			self:playSong(self.startPos / 1000)

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

	self:updateInput(dt)

	self.scripts:call("update", dt)
	PlayState.super.update(self, dt)

	if self.camZooming then
		game.camera.zoom = util.coolLerp(game.camera.zoom, self.camZoom, 3, dt * self.camZoomSpeed)
		self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt * self.camZoomSpeed)
	end
	self.camNotes.zoom = self.camHUD.zoom

	if not self.isDead and self.health <= 0 then self:tryGameOver() end

	if self.startedCountdown then
		if (self.buttons and game.keys.justPressed.ESCAPE) or controls:pressed("pause") then
			self:tryPause()
		end

		if controls:pressed("debug_1") then
			game.camera:unfollow()
			self:pauseSong()
			game.switchState(ChartingState())
		end

		if controls:pressed("debug_2") then
			game.camera:unfollow()
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
				self.downScroll = downscroll
			end,
			["middleScroll"] = function()
				self.middleScroll = ClientPrefs.data.middleScroll
				self:centerNotefields()
			end,
			["botplayMode"] = function()
				self.usedBotPlay = true
				self.playerNotefield.bot = ClientPrefs.data.botplayMode
			end,
			["backgroundDim"] = function()
				self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100
			end,
			["playback"] = function()
				self.playback = self:setSongPlayback(ClientPrefs.data.playback)
				self.timer.timeScale = self.playback
				self.tween.timeScale = self.playback
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
	self.gui:onSettingChange(category, setting)

	self.scripts:call("onSettingChange", category, setting)
end

function PlayState:goodNoteHit(note, time)
	self.scripts:call("goodNoteHit", note)

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

		local rating = self:getRating(note.time, time)

		notefield.lastSustain = isSustain and note or nil
		if (rating.name == "bad" or rating.name == "shit") then
			note:ghost()
		else
			if not isSustain then notefield:removeNote(note) end
		end

		local receptor = notefield.receptors[dir + 1]
		if receptor then
			if not event.strumGlowCancelled then
				receptor:play("confirm", true)
				if ClientPrefs.data.noteSplash and notefield.canSpawnSplash and rating.splash then
					receptor:spawnSplash()
				end
				receptor.holdTime = not isSustain and 0.18 or 0
			end
			if isSustain and not event.coverSpawnCancelled then
				local cover = receptor:spawnCover(note)
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
	self.gui:goodNoteHit(note, time, rating)

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

		self:resetStroke(notefield, dir, fullyHeldSustain)
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
		end
	end
	self.gui:noteMiss(note, dir)

	self.scripts:call(ghostMiss and "postMiss" or "postNoteMiss", funcParam)
end

function PlayState:recalculateRating(rating)
	if rating then
		local field = rating .. "s"
		self[field] = (self[field] or 0) + 1
	end
	self.gui:recalculateRating(rating)
end

function PlayState:tryPause()
	local event = self.scripts:call("paused")
	if event ~= Script.Event_Cancel then
		game.camera:unfollow()
		game.camera:freeze()
		self.camNotes:freeze()
		self.camHUD:freeze()

		self:pauseSong()

		if self.buttons then
			self:remove(self.buttons)
		end

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

		if self.buttons then
			self:remove(self.buttons)
		end

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

function PlayState:closeSubstate()
	self.scripts:call("substateClosed")
	PlayState.super.closeSubstate(self)

	game.camera:unfreeze()
	self.camNotes:unfreeze()
	self.camHUD:unfreeze()

	game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)

	if not self.startingSong then
		self:playSong()
		if Discord then self:updateDiscordRPC() end
	end

	if self.buttons then self:add(self.buttons) end
	self.paused = false

	self.scripts:call("postSubstateClosed")
end

function PlayState:endSong(skip)
	if skip == nil then skip = false end
	PlayState.seenCutscene = false
	self.startedCountdown = false
	self.boyfriend.waitReleaseAfterSing = false

	if self.storyMode and not PlayState.seenCutscene and not skip then
		PlayState.seenCutscene = true

		local cutscene = Cutscene(true, function(event)
			self:endSong(true)
		end)
		return
	end

	local event = self.scripts:call("endSong")
	if event == Script.Event_Cancel then return end
	game.sound.music.onComplete = nil

	if not self.usedBotPlay then
		Highscore.saveScore(PlayState.SONG.song, self.score, self.songDifficulty)
	end

	if self.chartingMode then
		game.switchState(ChartingState())
		return
	end

	game.sound.music:reset(true)
	local vocals
	for _, notefield in ipairs(self.notefields) do
		vocals = notefield.vocals
		if vocals then vocals:seek(time) end
	end

	if self.storyMode then
		PlayState.canFadeInReceptors = false
		if not self.usedBotPlay then
			PlayState.storyScore = PlayState.storyScore + self.score
		end

		table.remove(PlayState.storyPlaylist, 1)
		if #PlayState.storyPlaylist > 0 then
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
	self.timer.timeScale = 1

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)

	for _, notefield in ipairs(self.notefields) do
		if notefield.is then notefield:destroy() end
	end

	self.scripts:call("postLeave")
	self.scripts:close()
end

return PlayState
