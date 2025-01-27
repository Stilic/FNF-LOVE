local Signal = Classic:extend("Signal")

function Signal:new()
	self.listeners = {}
	self.onceCalls = {}
end

function Signal:add(listener, once)
	table.insert(self.listeners, listener)
end

function Signal:addOnce(listener)
	self:add(listener)
	self.onceCalls[listener] = true
end

function Signal:remove(listener)
	table.delete(self.listeners, listener)
end

function Signal:dispatch(...)
	for _, listener in ipairs(self.listeners) do
		local s, err = pcall(listener, ...)
		if not s then print(err) end
		if self.onceCalls[listener] then
			self:remove(listener)
			self.onceCalls[listener] = nil
		end
	end
end

function Signal:destroy()
	table.clear(self.listeners)
	table.clear(self.onceCalls)
end

return Signal
