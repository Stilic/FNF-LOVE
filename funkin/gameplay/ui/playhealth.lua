local PlayHealth = SpriteGroup:extend("PlayHealth")
-- todo urgently, rename this to smth else
-- kaoy

function PlayHealth:new(bfData, dadData, tracker)
	PlayHealth.super.new(self, 0, 0)

	self.maxHealth = 2
	self.iconScale = 1

	self.bg = Sprite():loadTexture(paths.getImage("skins/normal/healthBar"))
	self.bg:updateHitbox()

	self.bar = Bar(self.bg.x + 4, self.bg.y + 4,
		math.floor(self.bg.width - 8),
		math.floor(self.bg.height - 8), 0, self.maxHealth, true)

	if dadData.iconColor then
		self.bar.bg.color = dadData.iconColor
	end
	if bfData.iconColor then
		self.bar.color = bfData.iconColor
	end

	self:add(self.bg)
	self:add(self.bar)

	self.iconP1 = HealthIcon(dadData.icon, true)
	self.iconP2 = HealthIcon(bfData.icon)

	self.iconP1.y = self.bar.y + (self.bar.height - self.iconP1.height) / 2
	self.iconP2.y = self.bar.y + (self.bar.height - self.iconP2.height) / 2

	self:add(self.iconP1)
	self:add(self.iconP2)

	self.tracker = tracker or 1
	self.bar:setValue(self.tracker)
end

function PlayHealth:update(dt)
	PlayHealth.super.update(self, dt)

	self.bar:setValue(self.tracker)

	local mult = util.coolLerp(self.iconScale, 1, 15, dt)
	self.iconScale = mult
	self.iconP1.scale = {x = mult, y = mult}
	self.iconP2.scale = {x = mult, y = mult}

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

function PlayHealth:scaleIcons(val)
	self.iconScale = val
	self.iconP1.scale = {x = val, y = val}
	self.iconP2.scale = {x = val, y = val}
end

function Object:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = (game.width - self.bg.width) / 2 end
	if axes:find("y") then self.y = (game.height - self.bg.height) / 2 end
	return self
end

return PlayHealth
