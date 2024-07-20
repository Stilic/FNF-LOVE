local MenuList = SpriteGroup:extend("MenuList")

function MenuList.lerp(d, targ, factor, mult, add, dt, time)
	local formula = (math.remapToRange(targ, 0, 1, 0, factor) * mult) + add
	if time and time <= 0 then
		return formula
	end
	return util.coolLerp(d, formula, time or 9.6, dt)
end

function MenuList:new(type, attachPos)
	MenuList.super.new(self, 0, 0)
	self.type = type or "diagonal"
	self.attachPos = attachPos or "left"

	self.changeCallback = nil

	self.throttles = {}
	if self.type ~= "horizontal" then
		self.throttles[-1] = Throttle:make({controls.down, controls, "ui_up"})
		self.throttles[1] = Throttle:make({controls.down, controls, "ui_down"})
	else
		self.throttles[-1] = Throttle:make({controls.down, controls, "ui_left"})
		self.throttles[1] = Throttle:make({controls.down, controls, "ui_right"})
	end

	self.curSelected = 1
end

function MenuList:add(obj, attach)
	MenuList.super.add(self, obj)

	obj.ID = #self.members
	obj.target = 0

	obj.unfocusAlpha = 0.6

	obj.yAdd = game.height * 0.44
	obj.yMult = 120

	obj.xAdd = 60
	obj.xMult = 1

	obj.spaceFactor = 1.34

	if attach then
		attach.xAdd = 10
		attach.yAdd = -30
		obj.attach = attach
	end

	self:updatePositions(game.dt, 0)
end

function MenuList:updatePositions(dt, time)
	self.x, self.y = 0, 0
	for _, obj in ipairs(self.members) do
		if self.type == "diagonal" then
			obj.y = MenuList.lerp(
				obj.y, obj.target, obj.spaceFactor, obj.yMult, obj.yAdd, dt, time)
			obj.x = MenuList.lerp(
				obj.x, obj.target * 20, obj.spaceFactor, obj.xMult, obj.xAdd, dt, time)
		elseif self.type == "vertical" then
			obj.y = MenuList.lerp(
				obj.y, obj.target, obj.spaceFactor, obj.yMult, obj.yAdd, dt, time)
		elseif self.type == "horizontal" then
			obj.x = MenuList.lerp(
				obj.x, obj.target, obj.spaceFactor, obj.xMult, obj.xAdd, dt, time)
		end
		if obj.attach then
			obj.attach:update(dt)
			obj.attach:setPosition(self.attachPos == "left" and obj.x + obj:getWidth() +
					obj.attach.xAdd or obj.x - obj.attach.width - obj.attach.xAdd,
				obj.y + obj.attach.yAdd)
		end
	end
	for i, throttle in pairs(self.throttles) do
		if throttle:check() then
			if self.changeCallback then self.changeCallback(i) end
			self:changeSelection()
		end
	end
end

function MenuList:update(dt)
	MenuList.super.update(self, dt)
	self:updatePositions(dt)
end

function MenuList:changeSelection(c)
	if c ~= nil then
		self.curSelected = c
	end
	local bullshit = 0

	for _, item in ipairs(self.members) do
		item.target = bullshit - (self.curSelected - 1)
		bullshit = bullshit + 1

		item.alpha = item.unfocusAlpha
		if item.target == 0 then item.alpha = 1 end
		if item.attach then item.attach.alpha = item.alpha end
	end
end

function MenuList:__render(c)
	MenuList.super.__render(self, c)
	for _, obj in ipairs(self.members) do
		if obj.attach then
			obj.attach:__render(c)
		end
	end
end

function MenuList:destroy()
	MenuList.super.destroy(self)
	--for _, v in ipairs(self.throttles) do v:destroy() end
	-- it's returning a metatable error
	self.throttles = nil
end

return MenuList
