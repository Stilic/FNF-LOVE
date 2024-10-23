local Events = require "funkin.backend.scripting.events"

local GUI = SpriteGroup:extend("GUI")

function GUI:new()
	GUI.super.new(self)

	self.state = game.getState()
	self.notCreated = false

	local name = PlayState.SONG.gui or (Mods.currentMod and
		Mods.getMetadata(Mods.currentMod).gui or "default")
	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/gui/" .. name)

	self.scripts:set("self", self)

	local returned = self.scripts:call("create")
	if returned == Script.Event_Cancel then
		self.notCreated = true
		self.scripts:call("postCreate")
		return
	end

	self.healthBar = HealthBar(self.state.boyfriend.icon, self.state.dad.icon)
	self.healthBar:screenCenter("x")
	self:add(self.healthBar)

	local fontScore = paths.getFont("vcr.ttf", 16)
	self.scoreText = Text(0, 0, "", fontScore, Color.WHITE, "right")
	self.scoreText.outline.width = 1
	self.scoreText.antialiasing = false
	self:add(self.scoreText)

	self.botplayText = Text(0, 0, "[BOTPLAY]", fontScore, Color.WHITE)
	self.botplayText.outline.width = 1
	self.botplayText.antialiasing = false
	self.botplayText.visible = ClientPrefs.data.botplayMode
	self:add(self.botplayText)

	self.judgeSprites = Judgements(PlayState.SONG.skin)
	self.judgeSprites:screenCenter("x").y = self.judgeSprites.area.height * 1.5
	self:add(self.judgeSprites)

	self:readjust()
	self.scripts:call("postCreate")
end

function GUI:update(dt)
	GUI.super.update(self, dt)
	self.scripts:call("update", dt)
	if self.notCreated then
		self.scripts:call("postUpdate", dt)
		return
	end

	self.healthBar.value = util.coolLerp(self.healthBar.value, self.state.health, 15, dt)
	self.scripts:call("postUpdate", dt)
end

function GUI:step(s)
	self.scripts:call("step", s)
	self.scripts:call("postStep", s)
end

function GUI:beat(b)
	self.scripts:call("beat", b)
	if self.notCreated then
		self.scripts:call("postBeat", b)
		return
	end

	local val, healthBar = 1.2, self.healthBar
	healthBar.iconScale = val
	healthBar.iconP1:setScale(val)
	healthBar.iconP2:setScale(val)
	self.scripts:call("postBeat")
end

function GUI:section(s)
	self.scripts:call("section", s)
	self.scripts:call("postSection", s)
end

function GUI:recalculateRating(rating)
	self.scripts:call("recalculateRating", s)
	if self.notCreated then
		self.scripts:call("postRecalculateRating")
		return
	end

	self.scoreText.content = "Score: " .. util.formatNumber(math.floor(self.state.score))
	self.scoreText:__updateDimension()
	self:readjust()
	if rating then self:popUpScore(rating) end
	self.scripts:call("postRecalculateRating")
end

function GUI:onSettingChange(category, setting)
	if self.notCreated then
		self.scripts:call("onSettingChange", category, setting)
		return
	end

	if category == "gameplay" then
		switch(setting, {
			["botplayMode"] = function()
				self.botplayText.visible = ClientPrefs.data.botplayMode
			end,
			["downScroll"] = function()
				self:readjust()
			end
		})
	end
	self.scripts:call("onSettingChange", category, setting)
end

function GUI:readjust(setting)
	local downscroll = ClientPrefs.data.downScroll
	self.healthBar.y = game.height * (downscroll and 0.1 or 0.9)

	self.scoreText.x, self.scoreText.y = self.healthBar.x + self.healthBar.bg.width - 190, self.healthBar.y + 30
	self.botplayText.x, self.botplayText.y = self.scoreText.x + self.scoreText.width + 20, self.scoreText.y
end

function GUI:popUpScore(rating)
	local event = self.state.scripts:event('onPopUpScore', Events.PopUpScore())
	if not event.cancelled then
		self.judgeSprites.ratingVisible = not event.hideRating
		self.judgeSprites.comboNumVisible = not event.hideScore
		self.judgeSprites:spawn(rating, self.state.combo)
	end
end

function GUI:noteMiss(note, direction)
	local ghostMiss = dir ~= nil
	if not ghostMiss then dir = note.direction end

	local funcParam = ghostMiss and dir or note
	self.scripts:call(ghostMiss and "miss" or "noteMiss", funcParam)

	if self.notCreated then
		self.scripts:call("post" .. (ghostMiss and "Miss" or "NoteMiss"), funcParam)
		return
	end

	self:popUpScore()
	self.scripts:call("post" .. (ghostMiss and "Miss" or "NoteMiss"), funcParam)
end

function GUI:goodNoteHit(...)
	-- ...
end

function GUI:getWidth() return game.width end

function GUI:getHeight() return game.height end

return GUI
