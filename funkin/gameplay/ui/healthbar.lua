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

	self.iconP1 = HealthIcon(bfData.icon, true)
	self.iconP2 = HealthIcon(dadData.icon)

	self.iconP1.y = self.bar.y + (self.bar.height - self.iconP1.height) / 2
	self.iconP2.y = self.bar.y + (self.bar.height - self.iconP2.height) / 2

	self.bar.color = bfData.iconColor ~= nil and Color.fromString(bfData.iconColor) or Color.GREEN
	self.bar.color.bg = dadData.iconColor ~= nil and Color.fromString(dadData.iconColor) or Color.RED

	self:add(self.iconP1)
	self:add(self.iconP2)

	self.value = 1
	self.bar:setValue(1)
	self:scaleIcons(1)
end

function HealthBar:update(dt)
	HealthBar.super.update(self, dt)

	self.bar:setValue(self.value)

	local mult = util.coolLerp(self.iconScale, 1, 15, dt)
	self:scaleIcons(util.coolLerp(self.iconScale, 1, 15, dt))

	self.iconP1:updateHitbox()
	self.iconP2:updateHitbox()

	local iconOffset = 26
	self.iconP1.x = self.bar.x + (self.bar.width *
		(math.remapToRange(self.bar.percent, 0, 100, 100,
			0) * 0.01) - iconOffset)

	self.iconP2.x = self.bar.x + (self.bar.width *
			(math.remapToRange(self.bar.percent, 0, 100, 100,
				0) * 0.01)) -
		(self.iconP2.width - iconOffset)

	local perc1, perc2 = self.bar.percent <= 10, self.bar.percent >= 90

	self.iconP1:setState((perc1 and 2 or 1))
	self.iconP2:setState((perc2 and 2 or 1))
end

function HealthBar:scaleIcons(val)
	self.iconScale = val
	self.iconP1.scale = {x = val, y = val}
	self.iconP2.scale = {x = val, y = val}
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
