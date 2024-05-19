local Judgements = SpriteGroup:extend("Judgements")
Judgements.area = {width = 336, height = 135}

function Judgements:new(x, y)
	Judgements.super.new(self, x, y)
	self.timer = Timer()

	self.ratingVisible = true
	self.comboNumVisible = true
	self.comboSprVisible = false

	self.skin = PlayState.pixelStage and "pixel" or "default"
	self.antialiasing = not PlayState.pixelStage
end

function Judgements:update(dt)
	Judgements.super.update(self, dt)
	self.timer:update(dt)
end

function Judgements:createSprite(name, scale, alpha, duration)
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

function Judgements:spawn(rating, combo)
	local accel = PlayState.conductor.crotchet * 0.001

	if rating and self.ratingVisible then
		local areaHeight = self.area.height / 2
		local ratingSpr = self:createSprite(rating, PlayState.pixelStage and 4.7 or 0.7,
			1, accel)
		ratingSpr.x = (self.area.width - ratingSpr.width) / 2
		ratingSpr.y = (self.area.height - ratingSpr.height) / 2 - self.area.height / 3
		ratingSpr.acceleration.y = 550
		ratingSpr.velocity.y = ratingSpr.velocity.y - math.random(140, 175)
		ratingSpr.velocity.x = ratingSpr.velocity.x - math.random(0, 10)
		ratingSpr.visible = self.ratingVisible
	end

	if combo and (combo > 9 or combo < 0) then
		if self.comboNumVisible then
			local negative = combo < 0
			local comboStr = string.format(negative and "-%03d" or "%03d", math.abs(combo))
			local x = math.min((#comboStr - 3) * -36, 0)
			for i = 1, #comboStr do
				local digit = comboStr:sub(i, i)
				local isNegative = digit == "-"
				if isNegative then digit = "negative" end

				local comboNum = self:createSprite("num" .. digit, PlayState.pixelStage and 4.5 or 0.5, 1, accel * 2)
				x, comboNum.x, comboNum.y = x + comboNum.width + 4, x, self.area.height - comboNum.height

				comboNum.acceleration.y, comboNum.velocity.x, comboNum.velocity.y = math.random(200, 300),
					math.random(-5.0, 5.0), comboNum.velocity.y - math.random(140, 160)
			end
		end

		if self.comboSprVisible then
			local comboSpr = self:createSprite("combo", PlayState.pixelStage and 4.2 or 0.6,
				combo > 9 and 1 or 0, accel)
			comboSpr.x, comboSpr.y = self.area.width - comboSpr.width,
				self.area.height - comboSpr.height
			comboSpr.acceleration.y = 600
			comboSpr.velocity.y = comboSpr.velocity.y - 150
			comboSpr.velocity.x = comboSpr.velocity.x + math.random(1, 10)
		end
	end
end

function Judgements:screenCenter()
	self.x, self.y = (game.width - self.area.width) / 2,
		(game.height - self.area.height) / 2
end

return Judgements
