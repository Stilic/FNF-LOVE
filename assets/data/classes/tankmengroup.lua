local TankmenGroup = SpriteGroup:extend("TankmenGroup")
local TankmanSprite = require "tankmansprite"

function TankmenGroup:new()
	TankmenGroup.super.new(self)
	paths.getSparrowAtlas("stages/tank/tankmanKilled1") -- cache shit

	self.times = {}
	self.dirs = {}

	local animChart = Parser.getChart("stress", "picospeaker")
	if not animChart then
		return
	end

	for k, v in ipairs(animChart.notes.player) do table.insert(animChart.notes.enemy, v) end
	table.sort(animChart.notes.enemy, function(a, b) return a.t < b.t end)

	for _, note in ipairs(animChart.notes.enemy) do
		if love.math.randomBool(7) then
			table.insert(self.times, note.t)
			local isRight = note.d ~= 3
			table.insert(self.dirs, isRight)
		end
	end
end

function TankmenGroup:create(x, y, time, right)
	local tankman = self:recycle(TankmanSprite)

	tankman.x, tankman.y = x, y
	tankman.flipX = not right

	tankman.time = time
	tankman.endingOffset = math.random() + math.random(50, 200)
	tankman.runSpeed = math.random() + math.random(0.6, 1)
	tankman.right = right
end

function TankmenGroup:update(dt)
	TankmenGroup.super.update(self, dt)

	while true do
		local cutoff = PlayState.conductor.time + 3000
		if #self.times > 0 and self.times[1] <= cutoff then
			local time = table.remove(self.times, 1)
			local right = table.remove(self.dirs, 1)
			local x, y = 500, 200 + math.random(50, 100)
			self:create(x, y, time, right)
		else
			break
		end
	end
end

return TankmenGroup
