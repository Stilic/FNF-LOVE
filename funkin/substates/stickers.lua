local StickersSubstate = Substate:extend("StickersSubstate")
StickersSubstate.prevStickers = nil

local function sortByTime(a, b) return a.time < b.time end

function StickersSubstate:new(targState, prevStickers, stickerSet)
	StickersSubstate.super.new(self)
	self.targetState = targState or MainMenuState()

	local camera = Camera()
	game.cameras.add(camera, false)

	self.stickers = SpriteGroup()
	self.stickers:setScrollFactor()
	self.stickers.cameras = {camera}
	self:add(self.stickers)

	self.stickerSet = stickerSet

	self.createSticker = function(set, name, x, y)
		local sticker = Sprite(x or 0, y or 0, paths.getImage(
			'stickers/' .. set .. '/' .. name))
		sticker.name = set
		sticker.set = name
		sticker.scale = {x = 1.1, y = 1.1}
		sticker.angle = math.random(-60, 70)
		sticker.visible = false
		sticker:updateHitbox()
		self.stickers:add(sticker)
		return sticker
	end

	self.sounds = {}
	local folders = paths.getItems("sounds/stickers", "directory")
	if #folders > 0 then
		local r = math.random(#folders)
		local folder = "sounds/stickers/" .. folders[r]
		local sounds = paths.getItems(folder, "file")

		if #sounds > 0 then
			for _, sound in ipairs(sounds) do
				if sound:ext("ogg") then
					table.insert(self.sounds, "stickers/" .. folders[r]
						.. "/" .. sound:withoutExt())
				end
			end
		end
	end

	if self.stickerSet == nil then
		local sets = paths.getItems("data/stickers", "file")
		self.stickerSet = sets[math.random(#sets)]:withoutExt()
	end

	if prevStickers then self:unspawnStickers() else self:spawnStickers() end
end

function StickersSubstate:enter()
	self.skipTransIn, self.skipTransOut = true, true
	StickersSubstate.super.enter(self)
end

function StickersSubstate:spawnStickers()
	self.stickers:clear()
	local random, data, stks = math.random, self:getStickers(self.stickerSet), {}
	for _, set in ipairs(data.packs["all"]) do stks[set] = data.stickers[set] end
	local keys = {}
	for key, _ in pairs(stks) do table.insert(keys, key) end

	local xPos, yPos = -100, -100
	while xPos <= game.width do
		local sets = stks[keys[random(#keys)]]
		local sticker = sets[random(#sets)]

		local sticky = self.createSticker(data.name, sticker)
		sticky.x, sticky.y = xPos, yPos
		xPos = xPos + sticky.width / 2

		if xPos >= game.width then
			if yPos <= game.height then
				xPos, yPos = -100, yPos + math.random(70.0, 120.0)
			end
		end
	end

	table.shuffle(self.stickers.members)

	for i, sticker in ipairs(self.stickers.members) do
		sticker.time = math.remapToRange(i, 0, #self.stickers.members, 0, 0.9)

		Timer.after(sticker.time, function()
			if not self.stickers then return end

			sticker.visible = true
			if #self.sounds > 0 then
				game.sound.play(paths.getSound(self.sounds[random(#self.sounds)]))
			end

			local timer = i == #self.stickers.members and 2 or math.random(0.1, 1.9)
			Timer.after((1 / 24) * timer, function()
				if not sticker then return end
				sticker.scale = {x = 1, y = 1}

				if i == #self.stickers.members then
					self.targetState.skipTransIn = true
					self.targetState.persistentUpdate = true
					if self.parent then self.parent.skipTransOut = true end

					game.switchState(self.targetState)
					local superenter = self.targetState.enter
					self.targetState.enter = function(this)
						superenter(this)
						this:openSubstate(StickersSubstate(nil, true))
					end
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
	if not StickersSubstate.prevStickers then
		return self:close()
	end

	for _, s in ipairs(StickersSubstate.prevStickers) do
		local sticky = self.createSticker(s.name, s.set, s.x, s.y)
		sticky.time, sticky.visible = s.time, true
		sticky.angle = s.angle
		sticky.scale = {x = 1, y = 1}
	end

	for i, sticker in ipairs(self.stickers.members) do
		Timer.after(sticker.time, function()
			sticker.visible = false
			if #self.sounds > 0 then
				game.sound.play(paths.getSound(self.sounds[
					math.random(#self.sounds)]))
			end

			if i == #self.stickers.members then
				self:close()
				StickersSubstate.prevStickers = nil
			end
		end)
	end
end

function StickersSubstate:getStickers(set)
	local json = paths.getJSON('data/stickers/' .. set)
	return {
		name = json.name or set,
		artist = json.artist,
		packs = json.stickerPacks,
		stickers = json.stickers
	}
end

function StickersSubstate:close()
	StickersSubstate.super.close(self)
	self:destroy()
end

return StickersSubstate
