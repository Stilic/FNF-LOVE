local HealthIcon = Sprite:extend("HealthIcon")

HealthIcon.defaultIcon = "face"

function HealthIcon:new(icon, isPlayer)
	HealthIcon.super.new(self)

	self.isPlayer, self.isLegacyStyle = isPlayer or false, true
	self.flipX = self.isPlayer
	self.sprTracker = nil
	self:changeIcon(icon)
end

function HealthIcon:changeIcon(icon, ignoreDefault)
	if not icon or icon == "" or not paths.getImage("icons/" .. icon) then
		if ignoreDefault then return false end
		icon = HealthIcon.defaultIcon
	end

	self.icon = icon

	local hasOldSuffix = icon:endsWith("-old")
	self.isPixelIcon = icon:endsWith("-pixel") or
		(hasOldSuffix and icon:sub(1, -5):endsWith("-pixel"))
	self.isOldIcon = hasOldSuffix or
		(self.isPixelIcon and icon:sub(1, -7):endsWith("-old"))

	local path, isSparrow = "icons/" .. icon, paths.exists(paths.getPath("images/" .. path .. ".xml"), "file")
	self.isLegacyStyle = isSparrow or paths.exists(paths.getPath("images/" .. path .. ".txt"), "file")
	if self.isLegacyStyle then
		self:loadTexture(paths.getImage(path))
		if math.round(self.width / self.height) > 1 then
			self:loadTexture(self.texture, true,
				math.floor(self.width / 2),
				math.floor(self.height))
			self:addAnim("i", {0, 1}, 0)
			self:play("i")
		end
	else
		self:setFrames(isSparrow and paths.getSparrowAtlas(path) or paths.getPackerAtlas(path))

		self:addAnimByPrefix("idle", "idle", 24, true)
		self:addAnimByPrefix("winning", "winning", 24, true)
		self:addAnimByPrefix("losing", "losing", 24, true)
		self:addAnimByPrefix("toWinning", "toWinning", 24, false)
		self:addAnimByPrefix("toLosing", "toLosing", 24, false)
		self:addAnimByPrefix("fromWinning", "fromWinning", 24, false)
		self:addAnimByPrefix("fromLosing", "fromLosing", 24, false)

		self:play("idle")
	end

	self.iconOffset = {x = (self.width - 150) / 2, y = (self.height - 150) / 2}

	local zoom = self.isPixelIcon and 150 / self.height or 1
	self.zoom.x, self.zoom.y = zoom, zoom
	self.antialiasing = zoom < 2.5 and self.antialiasing
	self:updateHitbox()

	return true
end

function HealthIcon:updateAnimation(percent)
	self.curFrame = (self.isPlayer and percent or 100 - percent) <= 10 and 2 or 1
end

function HealthIcon:fixOffsets()
	self.offset.x, self.offset.y = self.iconOffset.x, self.iconOffset.y
end

function HealthIcon:update(dt)
	HealthIcon.super.update(self, dt)

	if self.sprTracker then
		self:setPosition(self.sprTracker.x + self.sprTracker:getWidth() + 10,
			self.sprTracker.y - 30)
	end
end

return HealthIcon
