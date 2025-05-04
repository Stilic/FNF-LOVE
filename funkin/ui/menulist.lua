local MenuList = SpriteGroup:extend("MenuList")
MenuList.selectionCache = {}

local defaultScrolls = {
	default = function(self, obj, dt, time)
		obj.y = self:lerp(dt, obj, "y", time)
		obj.x = self:lerp(dt, obj, "x", time, obj.target * 26)
	end,
	centered = function(self, obj, dt, time)
		obj:screenCenter("x")
		obj.y = self:lerp(dt, obj, "y", time)
	end,
	vertical = function(self, obj, dt, time)
		obj.y = self:lerp(dt, obj, "y", time)
	end,
	horizontal = function(self, obj, dt, time)
		obj.x = self:lerp(dt, obj, "x", time)
	end
}

local defaultHovers = {
	default = function(self, obj)
		obj.alpha = obj.target == 0 and 1 or 0.6
		if obj.child then obj.child.alpha = obj.alpha end
	end,
	anim = function(self, obj)
		for _, item in ipairs(self.members) do
			if item and item.animation:has("idle") and item.animation.name ~= "idle" then
				item.animation:play("idle")
			end
		end
		if obj and obj.animation:has("selected") and obj.animation.name ~= "selected" then
			obj.animation:play("selected")
		end
	end
}

function MenuList:new(sound, cache, scroll, hover)
	MenuList.super.new(self, 0, 0)
	self.width = game.width
	self.height = game.height

	self.sound = sound
	self.cache = cache
	self.scroll = scroll
	self.hover = hover

	self.childPos = "left"
	self.speed = 10

	self.lock = false
	self.curSelected = 1
	self.changeCallback = nil
	self.selectCallback = nil

	if cache then
		self.__key = tostring(game.getState())
		if MenuList.selectionCache[self.__key] then
			self.curSelected = MenuList.selectionCache[self.__key]
		else
			MenuList.selectionCache[self.__key] = 1
		end
	end

	self.throttles = {}
	if self.scroll ~= "horizontal" then
		self.throttles[-1] = Throttle:make({controls.down, controls, "ui_up"})
		self.throttles[1] = Throttle:make({controls.down, controls, "ui_down"})
	else
		self.throttles[-1] = Throttle:make({controls.down, controls, "ui_left"})
		self.throttles[1] = Throttle:make({controls.down, controls, "ui_right"})
	end
end

function MenuList:add(obj, child, unselectable)
	MenuList.super.add(self, obj)
	obj.unselectable = unselectable
	obj.ID = #self.members
	obj.target = 0

	obj.yAdd = obj.yAdd or self.height * .44
	obj.yMult = obj.yMult or 120
	obj.xAdd = obj.xAdd or 60
	obj.xMult = obj.xMult or 1
	obj.spaceFactor = obj.spaceFactor or 1.25

	if child then
		child.xAdd = child.xAdd or 10
		child.yAdd = child.yAdd or -30
		obj.child = child
	end

	self:updatePositions(game.dt, 0)
end

function MenuList:lerp(dt, obj, d, time, targ)
	targ = targ or obj.target
	time = time or self.speed
	local mult = d == "y" and obj.yMult or obj.xMult
	local add = d == "y" and obj.yAdd or obj.xAdd
	local factor = obj.spaceFactor

	local formula = (math.remapToRange(targ, 0, 1, 0, factor) * mult) + add
	if time <= 0 then return formula end
	return util.coolLerp(obj[d], formula, time, dt)
end

function MenuList:updatePositions(dt, time)
	local scrollFunc = type(self.scroll) == "function" and self.scroll or
		defaultScrolls[self.scroll or "default"]
	for i = 1, #self.members do
		local obj = self.members[i]
		if scrollFunc then scrollFunc(self, obj, dt, time) end
		if obj.child then
			obj.child:setPosition(self.childPos == "left" and obj.x + obj:getWidth() +
				obj.child.xAdd or obj.x - obj.child.width - obj.child.xAdd,
				obj.y + obj.child.yAdd)
			obj.child:update(dt)
		end
	end
end

function MenuList:update(dt)
	MenuList.super.update(self, dt)

	for i, throttle in pairs(self.throttles) do
		if throttle:check() and not self.lock and #self.members > 1 then
			self:changeSelection(i)
		end
	end

	for i = 1, #self.members do
		local obj = self.members[i]
		local hoverFunc = type(self.hover) == "function" and self.hover or
			defaultHovers[self.hover or "default"]
		if obj.active and hoverFunc then hoverFunc(self, obj, dt) end
	end

	if not self.lock and controls:pressed("accept") and self.selectCallback
		and #self.members > 0 then
		self.selectCallback(self.members[self.curSelected])
		self.lock = true
	end

	self:updatePositions(dt)
end

function MenuList:changeSelection(c, blockSound)
	c = c or 0
	if #self.members == 0 then return end

	-- locking all objects (who would?) may result in a infinite loop here
	self.curSelected = (self.curSelected - 1 + c) % #self.members + 1
	while self.members[self.curSelected].unselectable do
		self.curSelected = self.curSelected + (c ~= 0 and c or 1)
		self.curSelected = (self.curSelected - 1) % #self.members + 1
	end

	for i, member in ipairs(self.members) do
		member.target = i - self.curSelected
	end
	if self.cache then
		MenuList.selectionCache[self.__key] = self.curSelected
	end
	if self.changeCallback then
		self.changeCallback(self.curSelected, self.members[self.curSelected])
	end
	if #self.members > 1 and not blockSound and self.sound then
		util.playSfx(self.sound)
	end
end

function MenuList:getSelected()
	return self.members[self.curSelected]
end

function MenuList:__render(c)
	love.graphics.stencil(function()
		local x, y, w, h = self.x, self.y, self.width, self.height
		x, y = x - self.offset.x - (c.scroll.x * self.scrollFactor.x),
			y - self.offset.y - (c.scroll.y * self.scrollFactor.y)

		love.graphics.rectangle("fill", x, y, w, h)
	end, "replace", 1)
	love.graphics.setStencilTest("greater", 0)

	MenuList.super.__render(self, c)

	for i = 1, #self.members do
		local obj = self.members[i]
		if obj.child and obj.child:isOnScreen(c) then
			obj.child:__render(c)
		end
	end

	love.graphics.setStencilTest()
end

function MenuList:getWidth() return self.width end

function MenuList:getHeight() return self.height end

function MenuList:_getBoundary()
	local tx, ty = self.x or 0, self.y or 0
	if self.offset ~= nil then tx, ty = tx - self.offset.x, ty - self.offset.y end

	local xmin, ymin, xmax, ymax = math.huge, math.huge, -math.huge, -math.huge

	for _, member in ipairs(self.members) do
		local x, y, w, h, sx, sy = member:_getBoundary()

		x, y = x or 0, y or 0
		w, h = w or 0, h or 0
		sx, sy = sx or 1, sy or 1

		local mxmin, mxmax, mymin, mymax = x, x + w, y, y + h

		if mxmin < xmin then xmin = mxmin end
		if mxmax > xmax then xmax = mxmax end
		if mymin < ymin then ymin = mymin end
		if mymax > ymax then ymax = mymax end

		if member.child then
			x, y, w, h, sx, sy = member.child:_getBoundary()
			x, y = x or 0, y or 0
			w, h = w or 0, h or 0

			mxmin, mxmax, mymin, mymax = x, x + w, y, y + h

			if mxmin < xmin then xmin = mxmin end
			if mxmax > xmax then xmax = mxmax end
			if mymin < ymin then ymin = mymin end
			if mymax > ymax then ymax = mymax end
		end
	end

	tx, ty = tx + xmin, ty + ymin
	return tx, ty, xmax - xmin, ymax - ymin,
		math.abs(self.scale.x * self.zoom.x), math.abs(self.scale.y * self.zoom.y),
		self.origin.x, self.origin.y
end

return MenuList
