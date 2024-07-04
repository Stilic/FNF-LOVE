local MenuList = SpriteGroup:extend("MenuList")

function MenuList.lerpY(y, targY, mult, add, time)
	local formula = (math.remapToRange(targY, 0, 1, 0, 1.3) * mult) + add
	if time and time <= 0 then
		return formula
	end
	return util.coolLerp(y, formula, time or 9.6, dt)
end

function MenuList:new(type)
	MenuList.super.new(self, 0, 0)
	self.type = type or "vertical"
	self.curSelected = 1
end

function MenuList:add(obj)
	MenuList.super.add(self, obj)

	obj.ID = #self.members
	obj.targetY = 0

	obj.unfocusAlpha = 0.6

	obj.yAdd = (game.height * 0.44)
	obj.yMult = 120

	obj.xAdd = 70
	obj.xMult = 1

	obj.forceX = math.negative_infinity

	obj.y = MenuList.lerpY(obj.y, obj.targetY, obj.yMult, obj.yAdd, 0)

	self:updatePositions(game.dt)
end

function MenuList:updatePositions(dt)
	for _, obj in ipairs(self.members) do
		if self.type == "diagonal" then
			obj.y = MenuList.lerpY(obj.y, obj.targetY, obj.yMult, obj.yAdd)
			if obj.forceX ~= math.negative_infinity then
				obj.x = obj.forceX
			else
				obj.x = util.coolLerp(obj.x, (obj.targetY * 20) + obj.xAdd, 9.6, dt)
			end
		elseif self.type == "vertical" then
			obj.y = MenuList.lerpY(obj.y, obj.targetY, obj.yMult, obj.yAdd)
		elseif self.type == "centered" then
			obj:screenCenter("x")
			obj.y = MenuList.lerpY(obj.y, obj.targetY, obj.yMult, obj.yAdd)
		end
	end
end

function MenuList:update(dt)
	MenuList.super.update(self, dt)
	self:updatePositions(dt)
end

function MenuList:changeSelection()
	local bullshit = 0

	for _, item in ipairs(self.members) do
		item.targetY = bullshit - (self.curSelected - 1)
		bullshit = bullshit + 1

		item.alpha = item.unfocusAlpha

		if item.targetY == 0 then item.alpha = 1 end
	end
end

return MenuList
