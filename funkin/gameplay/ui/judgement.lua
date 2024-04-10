local Judgement = SpriteGroup:extend("Judgement")
Judgement.area = {width = 336, height = 135}

function Judgement:new(x, y)
	Judgement.super.new(self, x, y)
	self.timer = Timer()

	self.ratingVisible = true
	self.comboSprVisible = true
	self.comboNumVisible = true

	self.skin = PlayState.pixelStage and "pixel" or "default"
	self.antialiasing = not PlayState.pixelStage
end

function Judgement:update(dt)
	Judgement.super.update(self, dt)
	self.timer:update(dt)
end

function Judgement:spawn(rating, combo)
	local accel = PlayState.conductor.crotchet * 0.001

	local function create(name, scale, alpha, duration)
		local sprite = self:recycle()
		sprite:loadTexture(paths.getImage("skins/" .. self.skin .. "/" .. name))
		sprite:setGraphicSize(math.floor(sprite.width * scale))
		sprite.x, sprite.y = 0, 0
		sprite:updateHitbox()
		sprite.alpha = alpha
		sprite.antialiasing = antialias

		sprite.moves = true
		sprite.velocity.x = 0
		sprite.velocity.y = 0
		sprite.acceleration.y = 0
		sprite.antialiasing = self.antialiasing
		self.timer:after(duration, function()
			self.timer:tween(0.2, sprite, {alpha = 0}, "linear", function()
				self.timer:cancelTweensOf(sprite)
				sprite:kill()
			end)
		end)
		return sprite
	end

	if rating then
		local areaHeight = self.area.height / 2
		local ratingSpr = create(rating, PlayState.pixelStage and 4.7 or 0.7,
			1, accel)
		ratingSpr.x = (self.area.width - ratingSpr.width) / 2
		ratingSpr.y = (self.area.height - ratingSpr.height) / 2 - self.area.height / 3
		ratingSpr.acceleration.y = 550
		ratingSpr.velocity.y = ratingSpr.velocity.y - math.random(140, 175)
		ratingSpr.velocity.x = ratingSpr.velocity.x - math.random(0, 10)
		ratingSpr.visible = self.ratingVisible
	end

	if combo then
		local comboSpr = create("combo", PlayState.pixelStage and 4.2 or 0.6,
			combo > 9 and 1 or 0, accel)
		comboSpr.x, comboSpr.y = self.area.width - comboSpr.width,
			self.area.height - comboSpr.height
		comboSpr.acceleration.y = 600
		comboSpr.velocity.y = comboSpr.velocity.y - 150
		comboSpr.velocity.x = comboSpr.velocity.x + math.random(1, 10)
		comboSpr.visible = self.comboSprVisible

		local absCombo = math.abs(combo)
		local comboStr = string.format(combo > -1 and "%03d" or "-%03d", absCombo)

		for i = 1, #comboStr do
			local digit = tostring(comboStr:sub(i, i)) or ""
			if digit == "-" then digit = "negative" end

			local n = i - ((#comboStr + 1) - 3)
			local comboNum = create("num" .. digit, PlayState.pixelStage and 4.5 or 0.5,
				(combo > 9 or combo < 0) and 1 or 0, accel * 2)
			comboNum.x, comboNum.y = n * comboNum.width,
				self.area.height - comboNum.height

			comboNum.acceleration.y = math.random(200, 300)
			comboNum.velocity.y = comboNum.velocity.y - math.random(140, 160)
			comboNum.velocity.x = math.random(-5.0, 5.0)
			comboNum.visible = self.comboNumVisible
		end
	end
end

function Judgement:screenCenter()
	self.x, self.y = (game.width - self.area.width) / 2,
		(game.height - self.area.height) / 2
end

return Judgement
