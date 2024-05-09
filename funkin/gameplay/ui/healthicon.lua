local HealthIcon = Sprite:extend("HealthIcon")

HealthIcon.defaultIcon = "face"

function HealthIcon:new(icon, flip)
	HealthIcon.super.new(self)

	self.flipX = flip or false
	self.sprTracker = nil
	self:changeIcon(icon)
end

function HealthIcon:changeIcon(icon, ignoreDefault)
	if not icon or icon == "" or not paths.getImage("icons/" .. icon) then
		if ignoreDefault then return false end
		icon = HealthIcon.defaultIcon
	end
	self:loadTexture(paths.getImage("icons/" .. icon))

	self.icon = icon

	local hasOldSuffix = icon:endsWith("-old")
	self.isPixelIcon = icon:endsWith("-pixel") or
		(hasOldSuffix and icon:sub(1, -5):endsWith("-pixel"))
	self.isOldIcon = hasOldSuffix or
		(self.isPixelIcon and icon:sub(1, -7):endsWith("-old"))

	self:loadTexture(self.texture, true,
		math.floor(self.width / 2),
		math.floor(self.height))
	self:addAnim("i", {0, 1}, 0)
	self:play("i")

	self.iconOffset = {x = (self.width - 150) / 2, y = (self.height - 150) / 2}

	local zoom = self.isPixelIcon and 150 / self.height or 1
	self.zoom.x, self.zoom.y = zoom, zoom
	self.antialiasing = zoom < 2.5 and self.antialiasing
	self:updateHitbox()

	return true
end

function HealthIcon:fixOffsets()
	self.offset.x, self.offset.y = self.iconOffset.x, self.iconOffset.y
end

function HealthIcon:update(dt)
	HealthIcon.super.update(self, dt)

	if self.sprTracker ~= nil then
		self:setPosition(self.sprTracker.x + self.sprTracker:getWidth() + 10,
			self.sprTracker.y - 30)
	end
end

return HealthIcon
