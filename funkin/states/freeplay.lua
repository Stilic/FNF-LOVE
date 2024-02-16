local json = require "lib.json".encode
local FreeplayState = State:extend("FreeplayState")

FreeplayState.curSelected = 1
FreeplayState.curDifficulty = 2

function FreeplayState:enter()
	-- Update Presence
	if love.system.getDevice() == "Desktop" then
		Discord.changePresence({details = "In the Menus", state = "Freeplay Menu"})
	end

	self.lerpScore = 0
	self.intendedScore = 0

	self.inSubstate = false

	self.persistentUpdate = true
	self.persistentDraw = true

	self.songsData = {}
	self:loadSongs()

	FreeplayState.curSelected = math.min(FreeplayState.curSelected,
		#self.songsData)

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuDesat'))
	self:add(self.bg)
	self.bg:screenCenter()
	if #self.songsData > 0 then
		self.bg.color = Color.fromString(
			self.songsData[FreeplayState.curSelected].color)
	end

	self.grpSongs = Group()
	self:add(self.grpSongs)

	self.noSongTxt = Alphabet(0, 0, 'No Songs Here', true, false)
	self.noSongTxt:screenCenter()
	self:add(self.noSongTxt)
	self.noSongTxt.visible = (#self.songsData == 0)

	self.iconTable = {}
	if #self.songsData > 0 then
		for i = 0, #self.songsData - 1 do
			local songText = Alphabet(0, (70 * i) + 30,
				self.songsData[i + 1].name, true, false)
			songText.isMenuItem = true
			songText.targetY = i
			self.grpSongs:add(songText)

			if songText:getWidth() > 980 then
				local textScale = 980 / songText:getWidth()
				songText.scale.x = textScale
				for _, letter in ipairs(songText.lettersArray) do
					letter.x = letter.x * textScale
					letter.offset.x = letter.offset.x * textScale
				end
			end

			local icon = HealthIcon(self.songsData[i + 1].icon)
			icon.sprTracker = songText
			icon:updateHitbox()

			table.insert(self.iconTable, icon)
			self:add(icon)
		end
	end

	self.scoreText = Text(game.width * 0.7, 5, "", paths.getFont("vcr.ttf", 32),
		{1, 1, 1}, "right")
	self.scoreText.antialiasing = false

	self.scoreBG = Sprite(self.scoreText.x - 6, 0):make(1, 66, {0, 0, 0})
	self.scoreBG.alpha = 0.6
	self:add(self.scoreBG)

	self.diffText = Text(self.scoreText.x, self.scoreText.y + 36, "DIFFICULTY",
		paths.getFont("vcr.ttf", 24))
	self.diffText.antialiasing = false
	self:add(self.diffText)
	self:add(self.scoreText)

	if love.system.getDevice() == "Mobile" then
		self.buttons = ButtonGroup()
		self.buttons.width = 134
		self.buttons.height = 134

		local w = self.buttons.width

		local left = Button(2, game.height - w, 0, 0, "left")
		local up = Button(left.x + w, left.y - w, 0, 0, "up")
		local down = Button(up.x, left.y, 0, 0, "down")
		local right = Button(down.x + w, left.y, 0, 0, "right")

		local enter = Button(game.width - w, left.y, 0, 0, "return")
		enter.color = Color.GREEN
		local back = Button(enter.x - w, left.y, 0, 0, "escape")
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(right)

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
		game.buttons.add(self.buttons)
	end

	self.throttles = {}
	self.throttles.left = Throttle:make({controls.down, controls, "ui_left"})
	self.throttles.right = Throttle:make({controls.down, controls, "ui_right"})
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if #self.songsData > 0 then self:changeSelection() end
end

function FreeplayState:update(dt)
	self.lerpScore = util.coolLerp(self.lerpScore, self.intendedScore, 24, dt)
	self.scoreText.content = "PERSONAL BEST: " .. math.floor(self.lerpScore)

	self:positionHighscore()

	if not self.inSubstate then
		if #self.songsData > 0 and self.throttles then
			if self.throttles.up:check() then self:changeSelection(-1) end
			if self.throttles.down:check() then self:changeSelection(1) end
			if self.throttles.left:check() then self:changeDiff(-1) end
			if self.throttles.right:check() then self:changeDiff(1) end

			if controls:pressed('accept') then
				PlayState.storyMode = false

				local daSong = paths.formatToSongPath(
					self.songsData[FreeplayState.curSelected]
					.name)
				local diff =
					self.songsData[self.curSelected].difficulties[FreeplayState.curDifficulty]:lower()
				if self:checkSongAssets(daSong, diff) then
					if Keyboard.pressed.SHIFT then
						PlayState.loadSong(daSong, diff)
						PlayState.storyDifficulty = diff
						game.switchState(ChartingState())
					else
						game.switchState(PlayState(false, daSong, diff))
					end
				end
			end
		end
		if controls:pressed("back") then
			game.sound.play(paths.getSound('cancelMenu'))
			game.switchState(MainMenuState())
		end
	end

	if #self.songsData > 0 then
		local colorBG = Color.fromString(self.songsData[FreeplayState.curSelected].color)
		self.bg.color[1], self.bg.color[2], self.bg.color[3] =
			util.coolLerp(self.bg.color[1], colorBG[1], 3, dt),
			util.coolLerp(self.bg.color[2], colorBG[2], 3, dt),
			util.coolLerp(self.bg.color[3], colorBG[3], 3, dt)
	end

	FreeplayState.super.update(self, dt)
end

function FreeplayState:closeSubstate()
	self.inSubstate = false
	FreeplayState.super.closeSubstate(self)
end

function FreeplayState:changeDiff(change)
	if change == nil then change = 0 end
	local songdiffs = self.songsData[self.curSelected].difficulties

	FreeplayState.curDifficulty = FreeplayState.curDifficulty + change

	if FreeplayState.curDifficulty > #songdiffs then
		FreeplayState.curDifficulty = 1
	elseif FreeplayState.curDifficulty < 1 then
		FreeplayState.curDifficulty = #songdiffs
	end

	local daSong = paths.formatToSongPath(self.songsData[self.curSelected].name)
	self.intendedScore = Highscore.getScore(daSong,
		songdiffs[FreeplayState.curDifficulty]:lower())

	if #songdiffs > 1 then
		self.diffText.content = "< " ..
			songdiffs[FreeplayState.curDifficulty]:upper() ..
			" >"
	else
		self.diffText.content = songdiffs[FreeplayState.curDifficulty]:upper()
	end
	self:positionHighscore()
end

function FreeplayState:changeSelection(change)
	if change == nil then change = 0 end

	FreeplayState.curSelected = FreeplayState.curSelected + change

	if FreeplayState.curSelected > #self.songsData then
		FreeplayState.curSelected = 1
	elseif FreeplayState.curSelected < 1 then
		FreeplayState.curSelected = #self.songsData
	end

	local bullShit = 0

	for _, item in pairs(self.grpSongs.members) do
		item.targetY = bullShit - (FreeplayState.curSelected - 1)
		bullShit = bullShit + 1

		item.alpha = 0.6

		if item.targetY == 0 then item.alpha = 1 end
	end

	for _, icon in next, self.iconTable do icon.alpha = 0.6 end
	self.iconTable[FreeplayState.curSelected].alpha = 1

	if #self.songsData > 1 then game.sound.play(paths.getSound('scrollMenu')) end

	self:changeDiff(0)
end

function FreeplayState:positionHighscore()
	self.scoreText.x = game.width - self.scoreText:getWidth() - 6
	self.scoreBG.width = self.scoreText:getWidth() + 12
	self.scoreBG.x = self.scoreText.x + math.floor(self.scoreBG.width / 2) - 6
	self.diffText.x = math.floor(self.scoreBG.x - self.diffText:getWidth() / 2)
end

function FreeplayState:checkSongAssets(song, diff)
	local title = "Assets"
	local errorList = {}

	local jsonFile = paths.getJSON('songs/' .. song .. '/charts/' .. diff)
	local hasVocals = false
	if jsonFile then
		title = "Audio(s)"
		hasVocals = (jsonFile.song.needsVoices == true)
	else
		table.insert(errorList, 'songs/' .. song .. '/charts/' .. diff .. '.json')
	end
	if paths.getInst(song) == nil then
		table.insert(errorList, 'songs/' .. song .. '/Inst.ogg')
	end
	if hasVocals and paths.getVoices(song) == nil then
		table.insert(errorList, 'songs/' .. song .. '/Voices.ogg')
	end
	if #errorList <= 0 then return true end

	self.inSubstate = true
	self:openSubstate(AssetsErrorSubstate(title, errorList))
	return false
end

local function getSongMetadata(song)
	local song_metadata = paths.getJSON(
		'songs/' .. paths.formatToSongPath(song) ..
		'/meta')
	if song_metadata == nil then
		song_metadata = {}
		print("meta.json not found for " .. song)
	end
	return {
		name = song_metadata.name or song,
		icon = song_metadata.icon or 'face',
		color = song_metadata.color or '#0F0F0F',
		difficulties = song_metadata.difficulties or
			{'Easy', PlayState.defaultDifficulty, 'Hard'}
	}
end

function FreeplayState:loadSongs()
	if Mods.currentMod then
		if paths.exists(paths.getMods('data/freeplayList.txt'), 'file') then
			local listData = paths.getText('freeplayList'):gsub('\r', ''):split(
				'\n')
			for _, song in pairs(listData) do
				table.insert(self.songsData, getSongMetadata(song))
			end
		else
			if paths.exists(paths.getMods('data/weekList.txt'), 'file') then
				local listData = paths.getText('weekList'):gsub('\r', ''):split(
					'\n')
				for _, week in pairs(listData) do
					local weekData = paths.getJSON('data/weeks/weeks/' .. week)
					for _, song in ipairs(weekData.songs) do
						table.insert(self.songsData, getSongMetadata(song))
					end
				end
			else
				for _, str in pairs(love.filesystem.getDirectoryItems(
					paths.getMods('data/weeks/weeks'))) do
					local weekName = str:withoutExt()
					if str:endsWith('.json') then
						local weekData = paths.getJSON(
							'data/weeks/weeks/' .. weekName)
						for _, song in ipairs(weekData.songs) do
							table.insert(self.songsData, getSongMetadata(song))
						end
					end
				end
			end
		end
	else
		if paths.exists(paths.getPath('data/freeplayList.txt'), 'file') then
			local listData = paths.getText('freeplayList'):gsub('\r', ''):split(
				'\n')
			for _, song in pairs(listData) do
				table.insert(self.songsData, getSongMetadata(song))
			end
		else
			if paths.exists(paths.getPath('data/weekList.txt'), 'file') then
				local listData = paths.getText('weekList'):gsub('\r', ''):split(
					'\n')
				for _, week in pairs(listData) do
					local weekData = paths.getJSON('data/weeks/weeks/' .. week)
					for _, song in ipairs(weekData.songs) do
						table.insert(self.songsData, getSongMetadata(song))
					end
				end
			else
				for _, str in pairs(love.filesystem.getDirectoryItems(
					paths.getPath('data/weeks/weeks'))) do
					local weekName = str:withoutExt()
					if str:endsWith('.json') then
						local weekData = paths.getJSON(
							'data/weeks/weeks/' .. weekName)
						for _, song in ipairs(weekData.songs) do
							table.insert(self.songsData, getSongMetadata(song))
						end
					end
				end
			end
		end
	end
end

function FreeplayState:leave()
	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil
end

return FreeplayState
