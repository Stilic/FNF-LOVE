local Signal = Classic:extend("Signal")

function Signal:new()
	self.listeners = {}
end

function Signal:add(listener)
	table.insert(self.listeners, listener)
end

function Signal:addOnce(listener)
	local function wrapper(...)
		listener(...)
		self:remove(wrapper)
	end
	self:add(wrapper)
end


function Signal:remove(listener)
	for i, l in ipairs(self.listeners) do
		if l == listener then
			table.remove(self.listeners, i)
			return
		end
	end
end

function Signal:dispatch(...)
	for _, listener in ipairs(self.listeners) do
		listener(...)
	end
end

function Signal:destroy()
	self.listeners = {}
end

return Signal
