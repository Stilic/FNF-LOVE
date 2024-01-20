local TitleState = State:extend("TitleState")

TitleState.initialized = false

function TitleState:enter()
	Discord.changePresence({details = "In the Menus", state = "Title Screen"})

	self.curWacky = self:getIntroTextShit()

	self.skippedIntro = false
	self.danceLeft = false
	self.confirmed = false
	self.sickBeats = 0

	self.gfDance = Sprite(512, 40)
	self.gfDance:setFrames(paths.getSparrowAtlas("menus/title/gfDanceTitle"))
	self.gfDance:addAnimByIndices("danceLeft", "gfDance", {
		30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
	}, nil, 24, false)
	self.gfDance:addAnimByIndices("danceRight", "gfDance", {
		15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
	}, nil, 24, false)
	self.gfDance:play("danceRight")

	self.logoBl = Sprite(-150, -100)
	self.logoBl:setFrames(paths.getSparrowAtlas("menus/title/logoBumpin"))
	self.logoBl:addAnimByPrefix("bump", "logo bumpin", 24, false)
	self.logoBl:play("bump")
	self.logoBl:updateHitbox()

	self.titleText = Sprite(100, 576)
	self.titleText:setFrames(paths.getSparrowAtlas("menus/title/titleEnter"))
	self.titleText:addAnimByPrefix("idle", "Press Enter to Begin", 24)
	self.titleText:addAnimByPrefix("press", "ENTER PRESSED", 24)
	self.titleText:play("idle")
	self.titleText:updateHitbox()

	self.textGroup = Group()
	self:add(self.textGroup)

	self.ngSpr = Sprite(0, game.height * 0.52):loadTexture(paths.getImage(
		'menus/title/newgrounds_logo'))
	self:add(self.ngSpr)
	self.ngSpr.visible = false
	self.ngSpr:setGraphicSize(math.floor(self.ngSpr.width * 0.8))
	self.ngSpr:updateHitbox()
	self.ngSpr:screenCenter("x")

	if TitleState.initialized then
		self:skipIntro()
	else
		TitleState.initialized = true
	end

	self.conductor = Conductor(102)
	self.conductor.onBeat = bind(self, self.beat)

	if not game.sound.music or not game.sound.music:isPlaying() then
		game.sound.playMusic(paths.getMusic("freakyMenu"))
	end
	paths.addPersistant(paths.getModsAudio("music/freakyMenu"))

	if love.system.getDevice() == "Mobile" then
		local group = ButtonGroup()
		local enter = Button(0, 0, game.width, game.height, "return")
		enter.pressedAlpha = 0
		enter.releasedAlpha = 0
		group:add(enter)
		game.buttons.add(group)
	end
end

function TitleState:getIntroTextShit()
	local fullText = paths.getText('introText')
	local firstArray = fullText:split('\n')
	local swagGoodArray = firstArray[love.math.random(1, #firstArray)]

	return swagGoodArray:split('--')
end

function TitleState:update(dt)
	self.conductor.time = game.sound.music:tell() * 1000
	self.conductor:update(dt)

	local pressedEnter = controls:pressed("accept")

	if self.skippedIntro then
		if controls:pressed("debug_1") then
			game.sound.music:stop()
			game.switchState(ChartingState())
		end
		if controls:pressed("debug_2") then
			game.sound.music:stop()
			game.switchState(CharacterEditor())
		end
	end

	if pressedEnter and not self.confirmed and self.skippedIntro then
		self.confirmed = true
		self.titleText:play("press")
		game.camera:flash({1, 1, 1}, 2)
		game.sound.play(paths.getSound("confirmMenu"))
		Timer.after(1.5, function() game.switchState(MainMenuState()) end)
	end

	if pressedEnter and not self.skippedIntro and TitleState.initialized then
		self:skipIntro()
	end

	TitleState.super.update(self, dt)
end

function TitleState:createCoolText(textTable)
	for i = 1, #textTable do
		local money = Alphabet(0, 0, textTable[i], true, false)
		money:screenCenter("x")
		money.y = money.y + (i * 60) + 140
		self.textGroup:add(money)
	end
end

function TitleState:addMoreText(text)
	local coolText = Alphabet(0, 0, text, true, false)
	coolText:screenCenter("x")
	coolText.y = coolText.y + (#self.textGroup.members * 60) + 200
	self.textGroup:add(coolText)
end

function TitleState:deleteCoolText()
	while #self.textGroup.members > 0 do
		self.textGroup:remove(self.textGroup.members[1])
	end
end

function TitleState:beat(b)
	self.logoBl:play("bump", true)

	self.danceLeft = not self.danceLeft
	if self.danceLeft then
		self.gfDance:play("danceLeft")
	else
		self.gfDance:play("danceRight")
	end

	self.sickBeats = self.sickBeats + 1
	if self.sickBeats == 1 then
		self:createCoolText({
			'ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er'
		})
	elseif self.sickBeats == 3 then
		self:addMoreText('present')
	elseif self.sickBeats == 4 then
		self:deleteCoolText()
	elseif self.sickBeats == 5 then
		self:createCoolText({'In association', 'with'})
	elseif self.sickBeats == 7 then
		self:addMoreText('newgrounds')
		self.ngSpr.visible = true
	elseif self.sickBeats == 8 then
		self:deleteCoolText()
		self.ngSpr.visible = false
	elseif self.sickBeats == 9 then
		self:createCoolText({self.curWacky[1]})
	elseif self.sickBeats == 11 then
		self:addMoreText(self.curWacky[2])
	elseif self.sickBeats == 12 then
		self:deleteCoolText()
	elseif self.sickBeats == 13 then
		self:addMoreText('Friday')
	elseif self.sickBeats == 14 then
		self:addMoreText('Night')
	elseif self.sickBeats == 15 then
		self:addMoreText('Funkin')
	elseif self.sickBeats == 16 then
		self:skipIntro()
	end
end

function TitleState:skipIntro()
	if not self.skippedIntro then
		self:remove(self.ngSpr)
		self:remove(self.textGroup)
		self:add(self.gfDance)
		self:add(self.logoBl)
		self:add(self.titleText)
		game.camera:flash({1, 1, 1}, 4)
		self.skippedIntro = true
	end
end

return TitleState
