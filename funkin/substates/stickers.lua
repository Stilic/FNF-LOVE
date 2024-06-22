local StickersSubstate = Substate:extend("StickersSubstate")
StickersSubstate.prevStickers = nil

local function sortByTime(a, b) return a.time < b.time end

function StickersSubstate:new(targState)
	StickersSubstate.super.new(self)

	self.targetState = targState or MainMenuState()

	local cam = Camera()
	game.cameras.add(cam, false)

	self.stickers = SpriteGroup()
	self.stickers:setScrollFactor()
	self.stickers.cameras = {cam}
	self:add(self.stickers)

	self.createSticker = function(set, name, x, y)
		local spr = Sprite()
		spr.x, spr.y = x or 0, y or 0
		spr:loadTexture(paths.getImage('stickers/' .. set .. '/' .. name))
		return spr
	end

	self.sounds = {}
	-- it's supposed to be this? im not sure
	local sndPath = "sounds/stickers"
	local folders = paths.getItems(sndPath, "directory")
	if #folders > 0 then
		local folder = sndPath .. "/" .. folders[math.random(1, #folders)]
		local sounds = paths.getItems(folder, "file")

		if #sounds > 0 then
			for _, sound in ipairs(sounds) do
				if sound:endsWith(".ogg") then
					table.insert(self.sounds, folder:gsub("sounds/", "") ..
						"/" .. sound:withoutExt())
				end
			end
		else
			print("No sounds found!")
		end
	else
		print("Folders containing sticker sounds are missing!")
	end

	if StickersSubstate.prevStickers then
		for _, sticker in ipairs(StickersSubstate.prevStickers) do
			local s = self.createSticker(sticker.name, sticker.set,
				sticker.x, sticker.y)
			s.time, s.angle = sticker.time, sticker.angle
			s.scale.x, s.scale.y = sticker.scale.x, sticker.scale.y
			self.stickers:add(s)
			s:updateHitbox()
			table.sort(self.stickers.members, sortByTime)
		end
		self:unspawnStickers()
	else
		self:spawnStickers()
	end
end

function StickersSubstate:enter()
	self.skipTransIn = true
	self.skipTransOut = true
	StickersSubstate.super.enter(self)
end

function StickersSubstate:spawnStickers()
	if #self.stickers.members > 0 then self.stickers:clear() end

	local data, stickers = self:getStickers('stickers-set-1'), {}
	for _, stickerSet in ipairs(data.stickerPacks["all"]) do
		stickers[stickerSet] = data.stickers[stickerSet]
	end

	local xPos, yPos = -100, -100
	while xPos <= game.width do
		local stickerKeys = {}
		for key, _ in pairs(stickers) do table.insert(stickerKeys, key) end

		local rSet = stickerKeys[math.random(1, #stickerKeys)]
		local rSticker = stickers[rSet]
		local sticker = rSticker[math.random(1, #rSticker)]

		local sticky = self.createSticker(data.name, sticker)
		sticky.name = data.name
		sticky.set = sticker
		sticky.visible = false

		sticky.x, sticky.y = xPos, yPos
		xPos = xPos + sticky.width * 0.5
		sticky.scale = {x = 1.1, y = 1.1}
		sticky:updateHitbox()

		if xPos >= game.width then
			if yPos <= game.height then
				xPos = -100
				yPos = yPos + math.random(70.0, 120.0)
			end
		end

		sticky.angle = math.random(-60, 70)
		self.stickers:add(sticky)
	end

	table.shuffle(self.stickers.members)

	for i, sticker in ipairs(self.stickers.members) do
		sticker.time = math.remapToRange(i, 0, #self.stickers.members, 0, 0.9)

		Timer.after(sticker.time, function()
			if not self.stickers then return end

			sticker.visible = true
			if #self.sounds > 0 then
				local random = math.random(1, #self.sounds)
				game.sound.play(paths.getSound(self.sounds[random]))
			end

			local frameTimer = math.random(0.1, 2)
			if i == #self.stickers.members - 1 then frameTimer = 2 end

			Timer.after((1 / 24) * frameTimer, function()
				if not sticker then return end
				sticker.scale = {x = 1, y = 1}

				if i == #self.stickers.members then
					self.targetState.skipTransIn = true
					if self.parent then self.parent.skipTransOut = true end

					game.switchState(self.targetState)
				end
			end)
		end)
	end

	table.sort(self.stickers.members, sortByTime)

	local last = self.stickers.members[#self.stickers.members]
	last:updateHitbox()
	last.angle = 0
	last:screenCenter()

	StickersSubstate.prevStickers = self.stickers.members
end

function StickersSubstate:unspawnStickers()
	if not self.stickers.members or #self.stickers.members == 0 then
		self:close()
		return
	end

	for i, sticker in ipairs(self.stickers.members) do
		Timer.after(sticker.time, function()
			sticker.visible = false
			if #self.sounds > 0 then
				local random = math.random(1, #self.sounds)
				game.sound.play(paths.getSound(self.sounds[random]))
			end

			if not self.stickers or i == #self.stickers.members then
				self:close()
				StickersSubstate.prevStickers = nil
			end
		end)
	end
end

function StickersSubstate:getStickers(set)
	local obj, json = {}, paths.getJSON('data/stickers/' .. set)

	obj.name = json and json.name or set
	obj.artist = json and json.artist or ""
	obj.stickerPacks = {}
	obj.stickers = {}

	if json then
		for field, _ in pairs(json.stickerPacks) do
			obj.stickerPacks[field] = json.stickerPacks[field]
		end

		for field, _ in pairs(json.stickers) do
			obj.stickers[field] = json.stickers[field]
		end
	end

	return obj
end

function StickersSubstate:close()
	StickersSubstate.super.close(self)
	self:destroy()
end

return StickersSubstate
