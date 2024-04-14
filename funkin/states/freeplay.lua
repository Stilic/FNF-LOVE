local json = require "lib.json".encode
local FreeplayState = State:extend("FreeplayState")

FreeplayState.curSelected = 1
FreeplayState.curDifficulty = 2

function FreeplayState:enter()
	FreeplayState.super.enter(self)

	self.notCreated = false

	self.script = Script("data/states/freeplay", false)
	local event = self.script:call("create")
	if event == Script.Event_Cancel then
		self.notCreated = true
		return
	end

	-- Update Presence
	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Freeplay Menu"})
	end

	self.lerpScore = 0
	self.intendedScore = 0

	self.inSubstate = false

	self.persistentUpdate = true
	self.persistentDraw = true

	self.songsData = {}
	self:loadSongs()

	FreeplayState.curSelected = math.min(FreeplayState.curSelected, #self.songsData)

	self.bg = Sprite()
	self.bg:loadTexture(paths.getImage('menus/menuDesat'))
	self:add(self.bg)
	self.bg:screenCenter()
	self.bg:setGraphicSize(math.floor(self.bg.width * (game.width / self.bg.width)))
	self.bg:updateHitbox()
	self.bg:screenCenter()
	if #self.songsData > 0 then
		self.bg.color = Color.fromString(self.songsData[FreeplayState.curSelected].color)
	end

	self.grpSongs = Group()
	self:add(self.grpSongs)

	if #self.songsData == 0 then
		self.noSongTxt = Alphabet(0, 0, 'No songs here', true, false)
		self.noSongTxt:screenCenter()
		self:add(self.noSongTxt)
	end

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
		Color.WHITE, "right")
	self.scoreText.antialiasing = false

	self.scoreBG = Graphic(self.scoreText.x - 6, 0, 1, 66, Color.BLACK)
	self.scoreBG.alpha = 0.6
	self:add(self.scoreBG)

	self.diffText = Text(self.scoreText.x, self.scoreText.y + 36, "DIFFICULTY",
		paths.getFont("vcr.ttf", 24))
	self.diffText.antialiasing = false
	self:add(self.diffText)
	self:add(self.scoreText)

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local left = VirtualPad("left", 0, game.height - w)
		local up = VirtualPad("up", left.x + w, left.y - w)
		local down = VirtualPad("down", up.x, left.y)
		local right = VirtualPad("right", down.x + w, left.y)

		local enter = VirtualPad("return", game.width - w, left.y)
		enter.color = Color.GREEN
		local back = VirtualPad("escape", enter.x - w, left.y)
		back.color = Color.RED

		self.buttons:add(left)
		self.buttons:add(up)
		self.buttons:add(down)
		self.buttons:add(right)

		self.buttons:add(enter)
		self.buttons:add(back)

		self:add(self.buttons)
	end

	self.throttles = {}
	self.throttles.left = Throttle:make({controls.down, controls, "ui_left"})
	self.throttles.right = Throttle:make({controls.down, controls, "ui_right"})
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if #self.songsData > 0 then self:changeSelection() end

	self.script:call("postCreate")
end

function FreeplayState:update(dt)
	self.script:call("update", dt)
	if self.notCreated then return end

	self.lerpScore = util.coolLerp(self.lerpScore, self.intendedScore, 24, dt)
	if math.abs(self.lerpScore - self.intendedScore) <= 10 then
		self.lerpScore = self.intendedScore
	end
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
					if game.keys.pressed.SHIFT then
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
			util.playSfx(paths.getSound('cancelMenu'))
			game.switchState(MainMenuState())
		end
	end

	if #self.songsData > 0 then
		local colorBG = Color.fromString(self.songsData[FreeplayState.curSelected].color)
		self.bg.color = Color.lerpDelta(self.bg.color, colorBG, 3, dt)
	end
	FreeplayState.super.update(self, dt)

	self.script:call("postUpdate", dt)
end

function FreeplayState:closeSubstate()
	self.inSubstate = false
	FreeplayState.super.closeSubstate(self)
end

function FreeplayState:changeDiff(change)
	if change == nil then change = 0 end
	local songdiffs = self.songsData[self.curSelected].difficulties

	FreeplayState.curDifficulty = FreeplayState.curDifficulty + change
	FreeplayState.curDifficulty = (FreeplayState.curDifficulty - 1) % #songdiffs + 1

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
	FreeplayState.curSelected = (FreeplayState.curSelected - 1) % #self.songsData + 1

	local bullShit = 0

	for _, item in pairs(self.grpSongs.members) do
		item.targetY = bullShit - (FreeplayState.curSelected - 1)
		bullShit = bullShit + 1

		item.alpha = 0.6

		if item.targetY == 0 then item.alpha = 1 end
	end

	for _, icon in next, self.iconTable do icon.alpha = 0.6 end
	self.iconTable[FreeplayState.curSelected].alpha = 1

	if #self.songsData > 1 then util.playSfx(paths.getSound('scrollMenu')) end

	self:changeDiff(0)
end

function FreeplayState:positionHighscore()
	self.scoreText.x = game.width - self.scoreText:getWidth() - 6
	self.scoreBG.width = self.scoreText:getWidth() + 12
	self.scoreBG.x = self.scoreText.x - 6
	self.diffText.x = math.floor(self.scoreBG.x + (self.scoreBG.width - self.diffText:getWidth()) / 2)
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
		print("meta.json not found for " ..
			paths.formatToSongPath(song))
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
	local listData, func = nil, Mods.currentMod and paths.getMods or function(...)
		return paths.getPath(..., false)
	end
	if paths.exists(func('data/freeplayList.txt'), 'file') then
		listData = paths.getText('freeplayList')
	elseif paths.exists(func('data/freeplaySonglist.txt'), 'file') then
		listData = paths.getText('freeplaySonglist')
	else
		if paths.exists(func('data/weekList.txt'), 'file') then
			listData = paths.getText('weekList'):gsub('\r', ''):split(
				'\n')
			for _, week in pairs(listData) do
				local weekData = paths.getJSON('data/weeks/weeks/' .. week)
				for _, song in ipairs(weekData.songs) do
					table.insert(self.songsData, getSongMetadata(song))
				end
			end
		else
			for _, str in pairs(love.filesystem.getDirectoryItems(func('data/weeks/weeks'))) do
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
		return
	end
	listData = listData:gsub('\r', ''):split('\n')
	for _, song in pairs(listData) do
		table.insert(self.songsData, getSongMetadata(song))
	end
end

function FreeplayState:leave()
	self.script:call("leave")
	if self.notCreated then return end

	for _, v in ipairs(self.throttles) do v:destroy() end
	self.throttles = nil

	self.script:call("postLeave")
end

return FreeplayState
