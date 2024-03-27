local HealthIcon = Sprite:extend("HealthIcon")

HealthIcon.defaultIcon = "face"

function HealthIcon:new(icon, flip)
	HealthIcon.super.new(self)

	self.flipX = flip or false
	self.sprTracker = nil
	self:changeIcon(icon)
end

function HealthIcon:changeIcon(icon, ignoreDefault)
	if paths.getImage("icons/" .. icon) == nil then
		if ignoreDefault then return false end
		icon = HealthIcon.defaultIcon
	end
	self:loadTexture(paths.getImage("icons/" .. icon))

	self.icon = icon
	self.iconOffset = {x = 0, y = 0}

	local hasOldSuffix = icon:endsWith("-old")
	self.isPixelIcon = icon:endsWith("-pixel") or
		(hasOldSuffix and icon:sub(1, -5):endsWith("-pixel"))
	self.isOldIcon = hasOldSuffix or
		(self.isPixelIcon and icon:sub(1, -7):endsWith("-old"))

	self.availableStates = math.max(1, math.round(self.width / self.height))
	self.state = 0

	if self.availableStates > 1 then
		self:loadTexture(self.texture, true,
			math.floor(self.width / self.availableStates),
			math.floor(self.height))

		local _frames = table.new(self.availableStates, 0)
		for i = 1, self.availableStates do
			_frames[i] = i - 1
		end

		self:addAnim("i", _frames, 0)
		self:play("i")
	end

	local zoom = self.isPixelIcon and 150 / self.height or 1
	self.zoom.x, self.zoom.y = zoom, zoom
	self.antialiasing = zoom < 2.5 and self.antialiasing
	self:updateHitbox()

	return true
end

function HealthIcon:centerOffsets(...)
	HealthIcon.super.centerOffsets(self, ...)
	self.offset.x = self.offset.x + self.iconOffset.x
	self.offset.y = self.offset.y + self.iconOffset.y
end

function HealthIcon:fixOffsets(...)
	HealthIcon.super.fixOffsets(self, ...)
	self.offset.x = self.offset.x + self.iconOffset.x
	self.offset.y = self.offset.y + self.iconOffset.y
end

function HealthIcon:update(dt)
	HealthIcon.super.update(self, dt)

	if self.sprTracker ~= nil then
		self:setPosition(self.sprTracker.x + self.sprTracker:getWidth() + 10,
			self.sprTracker.y - 30)
	end
end

function HealthIcon:setState(state)
	if state > self.availableStates then state = 1 end
	self.state = state
	self.curFrame = state
end

return HealthIcon
