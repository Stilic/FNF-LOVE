Ease = loxreq "util.tween.ease"
local Instance = loxreq "util.tween.instance"

local Tween = {}
Tween.__index = Tween

function Tween:tween(object, props, duration, options)
	local tween = Instance()
	tween.manager = self
	tween:tween(object, props, duration, options)
	self.lastInstances = 0

	table.insert(self.instances, tween)
	return tween
end

function Tween:remove(instance)
	table.delete(self.instances, instance)
end

function Tween:update(dt)
	if self.lastInstances ~= #self.instances then
		-- print("New tween instance added, total of " .. #self.instances)
		self.lastInstances = #self.instances
	end

	if dt == 0 then return end

	for i = #self.instances, 1, -1 do
		local tween = self.instances[i]
		tween:update(dt * self.timeScale)
	end
end

function Tween:cancelTweensOf(object)
	for i = #self.instances, 1, -1 do
		local tween = self.instances[i]

		if tween.object == object then
			tween:destroy()
		end
	end
end

function Tween:clear()
	for i = #self.instances, 1, -1 do
		local tween = self.instances[i]
		if tween and tween.destroy then tween:destroy() end
	end
end

-- wrapper
function Tween.new() return setmetatable({instances = {}, timeScale = 1}, Tween) end
local def, module = Tween.new(), {}
for k in pairs(Tween) do
	if k ~= "__index" then
		module[k] = function(...) return def[k](def, ...) end
	end
end

return setmetatable(module, {__call = Tween.new})
