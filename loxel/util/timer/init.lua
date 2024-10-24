TimerManager = loxreq "util.timer.manager"

local Timer = Classic:extend("Timer")

Timer.globalManager = TimerManager()

function Timer:new(manager)
	self.manager = manager or Timer.globalManager
	self.manager:insert(self)
end

function Timer:start(time, func, loops)
	self:reset()
	self.time = time or 1
	self.timeLeft = self.time

	self.loops = loops or 1
	self.loopsLeft = self.loops

	self.onComplete = func
	self.active = true
end

function Timer:reset()
	self.time = 0
	self.timeLeft = 0

	self.loops = 1
	self.loopsLeft = 1
	self.elapsedLoops = 0

	self.onComplete = nil

	self.progress = 0
	self.active = false
	self.finished = false
	self.elapsedTime = 0

	return self
end

function Timer:update(dt)
	if not self.active or self.finished then return end

	self.elapsedTime = self.elapsedTime + dt
	self.timeLeft = math.max(self.timeLeft - dt, 0)
	self.progress = math.max(0, 1 - (self.timeLeft / self.time))

	if self.timeLeft <= 0 then
		self.elapsedLoops = self.elapsedLoops + 1
		if self.onComplete then self.onComplete(self) end
		if self.loops == 0 or self.elapsedLoops < self.loops then
			self.timeLeft = self.time
		else
			self:cancel()
		end
	end
end

function Timer:cancel()
	self.active = false
	self.finished = true
	self.manager:remove(self)
end

function Timer:destroy()
	self:cancel()
end

function Timer.wait(time, func)
	local timer = Timer()
	timer:start(time, func, 1)
	return timer
end

function Timer.loop(time, func, loops)
	local timer = Timer()
	timer:start(time, func, loops)
	return timer
end

return Timer
