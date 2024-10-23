local Ease = loxreq "util.tween.ease"

local Tween = Classic:extend("Tween")

local defaultOptions = {
	ease = "linear",
	type = "oneshot",
	startDelay = 0,
	loopDelay = 0
}

-- This is WIP - some code needs to be remade and it lacks chain support

function Tween:tween(object, properties, duration, options)
	options = options or table.clone(defaultOptions)

	self:reset()
	self.object = object or {}
	self.props = properties or {}
	self.duration = duration or 1

	self.ogprops = {}
	for prop in pairs(self.props) do
		self.ogprops[prop] = self.object[prop]
	end

	self.ease = options.ease or "linear"
	self.type = options.type or "oneshot"
	self.forward = options.type ~= "backward"

	self.onComplete = options.onComplete
	self.onStart = options.onStart
	self.onUpdate = options.onUpdate
	self.startDelay = options.startDelay or 0
	self.loopDelay = options.loopDelay or 0

	self.active = true
end

function Tween:new()
	self.object = nil
	self.props = nil
	self.duration = 0
	self.ogprops = nil

	self.ease = "linear"
	self.type = "oneshot"

	self.onComplete = nil
	self.onStart = nil
	self.onUpdate = nil
	self.startDelay = 0
	self.loopDelay = 0

	self.forward = false

	self.progress = 0
	self.active = false
	self.executions = 0
	self.finished = false
	self.percent = 0
	self.time = 0

	return self
end

Tween.reset = Tween.new

function Tween:update(dt)
	if self.finished or not self.active then return end

	if self.startDelay > 0 then
		self.startDelay = self.startDelay - dt
	else
		if self.onStart then self.onStart(self) end
		self.onStart = nil

		self.time = self.time + dt

		local progress = self.time / self.duration
		self.progress = progress
		if not self.forward then progress = 1 - progress end

		local easedp = Ease[self.ease] and Ease[self.ease](progress)
			or self.ease(progress)

		for prop, target in pairs(self.props) do
			local tstart = self.forward and self.ogprops[prop] or target
			local tend = self.forward and target or self.ogprops[prop]
			if self.forward and self.type == "pingpong" then
				self.object[prop] = tend + (tstart - tend) * easedp
			else
				self.object[prop] = tstart + (tend - tstart) * easedp
			end
		end

		if progress >= 1 and self.forward then
			self.forward = false
			self.time = 0
			self.startDelay = self.loopDelay
		elseif progress <= 0 and not self.forward then
			self.forward = true
			self.time = 0
			self.startDelay = self.loopDelay
		end
		if self.onUpdate then self.onUpdate(self) end

		if (progress >= 1 or progress <= 0) then self:complete() end
	end
end

function Tween:complete()
	for prop, target in pairs(self.props) do
		self.object[prop] = target
	end

	if self.type == "oneshot" or self.type == "backward" then
		self.finished = true
		self:destroy()
	elseif self.type == "persist" then
		self.time = 0
		self.finished = true
	elseif self.type == "looping" then
		self.finished = false
		self.time = 0
		self.executions = self.executions + 1
		self.startDelay = self.loopDelay
	elseif self.type == "pingpong" then
		self.finished = false
		self.executions = self.executions + 1

		if not self.forward then
			for prop, target in pairs(self.ogprops) do
				self.object[prop] = target
			end
		end
	end
	if self.onComplete then self.onComplete(self.object) end
end

function Tween:pause() self.active = true end

function Tween:resume() self.active = false end

function Tween:cancel()
	self:reset()
	self:destroy()
end

function Tween:destroy()
	if self.manager then self.manager:remove(self) end
end

return Tween
