local Stickers = SpriteGroup:extend("Stickers")
Stickers.previous = nil

local function sortByTime(a, b) return a.time < b.time end
local random = math.random

function Stickers:new(stickerSet, state)
	Stickers.super.new(self)

	self.curState = game.getState()

	local cam = Camera()
	game.cameras.add(cam, false)
	self.cameras = {cam}

	if self.stickerSet == nil then
		local sets = paths.getItems("data/stickers", "file", "json")
		self.stickerSet = table.random(sets):withoutExt()
	else
		self.stickerSet = stickerSet
	end

	self.sounds = {}
	self.timer = Timer()

	local folders = paths.getItems("sounds/stickers", "directory")
	if #folders > 0 then
		local r = random(#folders)
		local folder = "sounds/stickers/" .. folders[r]
		local sounds = paths.getItems(folder, "file", "ogg")

		if #sounds > 0 then
			for _, sound in ipairs(sounds) do
				table.insert(self.sounds, "stickers/" .. folders[r]
					.. "/" .. sound:withoutExt())
			end
		end
	end

	if not Stickers.previous then
		self:clear()

		local data, stks = self:getStickers(self.stickerSet), {}
		for _, set in ipairs(data.packs["all"]) do stks[set] = data.stickers[set] end
		local keys = table.keys(stks, true)

		local xPos, yPos = -100, -100
		while xPos <= game.width do
			local sets = stks[keys[random(#keys)]]
			local sticker = sets[random(#sets)]

			local sticky = self:createSticker(data.name, sticker, xPos, yPos)
			xPos = xPos + sticky.width / 2

			if xPos >= game.width then
				if yPos <= game.height then
					xPos, yPos = -100, yPos + random(70.0, 120.0)
				end
			end
		end

		self.isDirty = true
	end
	if state then self:start(state) end
end

function Stickers:createSticker(set, name, x, y)
	local sticker = Sprite(x or 0, y or 0, paths.getImage(
		'stickers/' .. set .. '/' .. name))
	sticker.name = set
	sticker.set = name
	if #self.sounds > 0 then
		sticker.sound = paths.getSound(table.random(self.sounds))
	end
	sticker.scale:set(1.1, 1.1)
	sticker.angle = math.random(-60, 70)
	sticker.visible = false
	sticker:updateHitbox()
	self:add(sticker)
	return sticker
end

function Stickers:spawn()
	table.shuffle(self.members)

	for i, sticker in ipairs(self.members) do
		sticker.time = math.remapToRange(i, 0, #self.members, 0, 0.9)

		Timer.wait(sticker.time, function()
			sticker.visible = true
			if sticker.sound then util.playSfx(sticker.sound) end

			local timer = (i == #self.members) and 2 or random(0, 200) / 100
			Timer.wait((1 / 24) * timer, function()
				sticker.scale:set(1, 1)

				if i == #self.members then
					if not self.targetState then return self:start() end

					self.targetState.skipTransIn = true
					self.curState.skipTransOut = true

					game.switchState(self.targetState)
					local superenter = self.targetState.enter
					self.targetState.enter = function(this)
						superenter(this)
						local stickers = Stickers()
						stickers:start()
						this:add(stickers)
					end
				end
			end)
		end)
	end

	self:sort(sortByTime)

	local last = self.members[#self.members]
	last:updateHitbox()
	last.angle = 0
	last:screenCenter()

	Stickers.previous = self.members
end

function Stickers:unspawn()
	if not Stickers.previous then return end

	for _, s in ipairs(Stickers.previous) do
		local sticky = self:createSticker(s.name, s.set, s.x, s.y)
		sticky.time, sticky.visible = s.time, true
		sticky.angle = s.angle
		sticky.scale:set(1, 1)
	end

	for i, sticker in ipairs(self.members) do
		Timer.wait(sticker.time, function()
			sticker.visible = false
			if sticker.sound then util.playSfx(sticker.sound) end

			if i == #self.members then
				Stickers.previous = nil
				self:__removeFromCache() -- sorry
				self:destroy()
			end
		end)
	end
end

function Stickers:start(target)
	self.targetState = target or MainMenuState()
	; (Stickers.previous and Stickers.unspawn or Stickers.spawn)(self)
	-- semicolon is to avoid ambiguous syntax error!!
end

function Stickers:update(dt)
	-- avoid some visual problems
	if self.isDirty then
		self.isDirty = nil
		self.nextIsDirty = true
		return
	elseif self.nextIsDirty then
		self.nextIsDirty = nil
		return
	end

	Stickers.super.update(self, dt)
	self.timer:update(dt)
end

function Stickers:getStickers(set)
	local json = paths.getJSON('data/stickers/' .. set)
	return {
		name = json.name or set,
		artist = json.artist or "unknown",
		packs = json.stickerPacks or {},
		stickers = json.stickers or {}
	}
end

function Stickers:__removeFromCache()
	for _, sticker in ipairs(self.members) do
		for path, cache in pairs(paths.images) do
			if cache == sticker.texture then
				paths.images[path]:release()
				paths.images[path] = nil
				break
			end
		end
	end
end

return Stickers
