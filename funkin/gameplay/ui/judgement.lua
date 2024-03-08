local Judgement = SpriteGroup:extend("Judgement")

function Judgement:new(x, y)
	Judgement.super.new(self, x, y)
	self.timer = Timer()

	self.ratingVisible = true
	self.comboSprVisible = true
	self.comboNumVisible = true
end

function Judgement:update(dt)
	Judgement.super.update(self, dt)
	self.timer:update(dt)
end

function Judgement:spawn(rating, combo)
	if rating == nil then rating = "shit" end

	local accel = PlayState.conductor.crotchet * 0.001
	local antialias = not PlayState.pixelStage
	local uiStage = PlayState.pixelStage and "pixel" or "normal"

	local function create(path, scale, x, y, alpha, duration)
		local sprite = self:recycle()
		sprite:loadTexture(paths.getImage("skins/" .. uiStage .. "/" .. path))
		sprite:setGraphicSize(math.floor(sprite.width * scale))
		sprite:updateHitbox()
		sprite.x = x
		sprite.y = y
		sprite.alpha = alpha
		sprite.antialiasing = antialias

		sprite.moves = true
		sprite.velocity.x = 0
		sprite.velocity.y = 0
		sprite.acceleration.y = 0
		sprite.antialiasing = antialias
		self.timer:after(duration, function()
			self.timer:tween(0.2, sprite, {alpha = 0}, "linear", function()
				self.timer:cancelTweensOf(sprite)
				sprite:kill()
			end)
		end)
		return sprite
	end

	local ratingSpr = create(rating, PlayState.pixelStage and 4.7 or 0.7,
			0, 0, combo > 0 and 1 or 0, accel)
	ratingSpr.x, ratingSpr.y = (1280 - ratingSpr.width) / 2 + 190, (720 - ratingSpr.height) / 2 - 60
	ratingSpr.acceleration.y = 550
	ratingSpr.velocity.y = ratingSpr.velocity.y - math.random(140, 175)
	ratingSpr.velocity.x = ratingSpr.velocity.x - math.random(0, 10)
	ratingSpr.visible = self.ratingVisible

	local comboSpr = create("combo", PlayState.pixelStage and 4.2 or 0.6,
			0, 0, combo > 9 and 1 or 0, accel)
	comboSpr.x, comboSpr.y = (1280 - comboSpr.width) / 2 + 250, (720 - comboSpr.height) / 2
	comboSpr.acceleration.y = 600
	comboSpr.velocity.y = comboSpr.velocity.y - 150
	comboSpr.velocity.x = comboSpr.velocity.x + math.random(1, 10)
	comboSpr.visible = self.comboSprVisible

	local coolX, comboStr = 1280 * 0.55, string.format("%03d", combo)
	if combo < 0 then comboStr = string.format("-%03d", math.abs(combo)) end
	local lastSpr
	for i = 1, #comboStr do
		local digit = tostring(comboStr:sub(i, i)) or ""
		if digit == "-" then digit = "negative" end
		local comboNum = create("num" .. digit, PlayState.pixelStage and 4.5 or 0.5,
				0, 0, (combo >= 10 or combo < 0) and 1 or 0, accel * 2)
		comboNum.x, comboNum.y = (lastSpr and lastSpr.x or coolX - 90) + comboNum.width, ratingSpr.y + 115
		comboNum.acceleration.y = math.random(200, 300)
		comboNum.velocity.y = comboNum.velocity.y - math.random(140, 160)
		comboNum.velocity.x = math.random(-5.0, 5.0)
		comboNum.visible = self.comboNumVisible

		lastSpr = comboNum
	end
end

return Judgement
