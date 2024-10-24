local TimerManager = Classic:extend("TimerManager")

function TimerManager:new(timeScale)
	self.instances = {}
	self.timeScale = timeScale or 1
end

function TimerManager:insert(instance)
	table.insert(self.instances, instance)
end

function TimerManager:remove(instance)
	table.delete(self.instances, instance)
end

function TimerManager:clear()
	for i = #self.instances, 1, -1 do
		local timer = self.instances[i]
		timer:cancel()
	end
end

function TimerManager:update(dt)
	if dt == 0 then return end
	for i = #self.instances, 1, -1 do
		local timer = self.instances[i]
		timer:update(dt * self.timeScale)
	end
end

return TimerManager
