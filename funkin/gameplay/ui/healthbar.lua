local HealthBar = SpriteGroup:extend("HealthBar")

function HealthBar:new(bfData, dadData, skin)
	HealthBar.super.new(self, 0, 0)

	self.maxHealth = 2

	self.bg = Sprite():loadTexture(paths.getImage("skins/default/healthBar"))
	self.bg:updateHitbox()

	self.bar = Bar(self.bg.x + 4, self.bg.y + 4,
		math.floor(self.bg.width - 8),
		math.floor(self.bg.height - 8), 0, self.maxHealth, true)

	self:add(self.bg)
	self:add(self.bar)

	self.iconP1, self.iconP2, self.iconScale =
		HealthIcon(bfData.icon, true), HealthIcon(dadData.icon), 1

	local y = self.bar.y
	self.iconP1.y = y - self.iconP1.height / 2
	self.iconP2.y = y - self.iconP2.height / 2

	self.bar.color =
		bfData.iconColor ~= nil and Color.fromString(bfData.iconColor) or Color.GREEN
	self.bar.color.bg =
		dadData.iconColor ~= nil and Color.fromString(dadData.iconColor) or Color.RED

	self:add(self.iconP1)
	self:add(self.iconP2)

	self.value = 1
	self.bar:setValue(1)
end

function HealthBar:update(dt)
	HealthBar.super.update(self, dt)

	self.bar:setValue(self.value)

	local val = util.coolLerp(self.iconScale, 1, 15, dt)
	self.iconScale = val
	self.iconP1:setScale(val)
	self.iconP2:setScale(val)

	local healthPercent, iconOffset = self.bar.percent, 26
	self.iconP1.x = self.bar.x + self.bar.width *
		(math.remapToRange(healthPercent, 0, 100, 100,
			0) * 0.01) + (150 * self.iconP1.scale.x - 150) / 2 - iconOffset
	self.iconP2.x = self.bar.x + (self.bar.width *
		(math.remapToRange(healthPercent, 0, 100, 100,
			0) * 0.01)) - (150 * self.iconP2.scale.x) / 2 - iconOffset * 2

	self.iconP1:updateAnimation(healthPercent)
	self.iconP2:updateAnimation(healthPercent)
end

function HealthBar:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.bg.width) / 2 end
	if axes:find("y") then self.y = (game.height - self.bg.height) / 2 end
	return self
end

function HealthBar:getWidth()
	return self.bg.width
end

function HealthBar:getHeight()
	return self.bg.height
end

return HealthBar
