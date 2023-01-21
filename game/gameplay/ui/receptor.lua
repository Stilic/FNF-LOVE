local Receptor = Sprite:extend()

function Receptor:new(x, y, data, player)
	Receptor.super.new(self, x, y)
	self:setFrames(paths.getSparrowFrames("skins/normal/NOTE_assets"))

	self.data = data
	self.player = player
	self.confirmTimer = 0

	self:setGraphicSize(math.floor(self.width * 0.7))

	local dir = Note.directions[data + 1]
	self:addAnimByPrefix("static", "arrow" .. string.upper(dir), 24, false)
	self:addAnimByPrefix("pressed", dir .. " press", 24, false)
	self:addAnimByPrefix("confirm", dir .. " confirm", 24, false)

	self:updateHitbox()
end

function Receptor:update(dt)
	if self.confirmTimer > 0 then
		self.confirmTimer = self.confirmTimer - dt
		if self.confirmTimer <= 0 then self:play("static") end
	end

	Receptor.super.update(self, dt)
end

function Receptor:init()
	self:play("static")
	self.x = self.x + 50 + Note.swagWidth * self.data + (push.getWidth() / 2) *
				 self.player
end

function Receptor:play(anim, force)
	Receptor.super.play(self, anim, force)

	self:centerOffsets()
	self:centerOrigin()

	if anim == "confirm" then
		if self.data == 0 then
			self.offset.x, self.offset.y = self.offset.x - 1, self.offset.y - 2
		elseif self.data == 1 then
			self.offset.x, self.offset.y = self.offset.x - 2.5,
										   self.offset.y - 2
		elseif self.data == 2 then
			self.offset.x, self.offset.y = self.offset.x - 1,
										   self.offset.y - 1.5
		elseif self.data == 3 then
			self.offset.x = self.offset.x - 1.5
		end
	end
end

return Receptor
