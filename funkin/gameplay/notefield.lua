local Notefield = ActorGroup:extend("Notefield")

function Notefield:new(x, y, keys, noteskin)
	Notefield.super.new(self, x, y, 0)

	self.noteWidth = math.floor(170 * 0.67)
	self.height = 500
	self.keys = keys

	self.input = 0

	self.hits = 0
	self.sicks = 0
	self.goods = 0
	self.bads = 0
	self.shits = 0

	local startx, y = -self.noteWidth / 2 - (self.noteWidth * keys / 2), -self.height / 2
	self.receptors = ActorGroup(0, 0, 0, false)
	self.notes = ActorGroup(0, 0, 0, false)

	for i = 1, keys do
		local receptor = Receptor(startx + self.noteWidth * i, y, i - 1, noteskin)
		self.receptors:add(receptor)
	end

	self:add(self.receptors)
	self:add(self.notes)

	self:getWidth()
end

function Notefield:screenCenter(axes)
	if axes == nil then axes = "xy" end
	if axes:find("x") then self.x = game.width / 2 end
	if axes:find("y") then self.y = game.height / 2 end
	if axes:find("z") then self.z = 0 end
	return self
end

function Notefield:getWidth()
	self.width = self.noteWidth * self.keys
	return self.width
end

function Notefield:getHeight()
	return self.height
end

return Notefield
