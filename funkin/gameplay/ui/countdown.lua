local Countdown = SpriteGroup:extend("Countdown")

function Countdown:new()
	Countdown.super.new(self)

	self.playback = 1
	self.duration = .8
	self.data = {
		{sound = "skins/normal/intro3",  image = nil},
		{sound = "skins/normal/intro2",  image = "skins/normal/ready"},
		{sound = "skins/normal/intro1",  image = "skins/normal/set"},
		{sound = "skins/normal/introGo", image = "skins/normal/go"}
	}
end

function Countdown:doCountdown(beat)
	local data = self.data[beat]
	if not data then return end

	if data.sound then
		game.sound.play(paths.getSound(data.sound)):setPitch(self.playback)
	end
	if data.image then
		local countdownSprite = Sprite()
		countdownSprite:loadTexture(paths.getImage(data.image))
		countdownSprite:updateHitbox()

		countdownSprite.antialiasing = self.antialiasing
		countdownSprite:centerOffsets()

		Timer.tween(self.duration, countdownSprite, {alpha = 0}, "in-out-cubic", function()
			self:remove(countdownSprite)
			countdownSprite:destroy()
		end)
		self:add(countdownSprite)
	end
end

return Countdown
