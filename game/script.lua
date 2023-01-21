local Script = Object:extend()

local chunkMt = { __index = _G }

function Script:new(path)
	self.path = path
	self.variables = {}
	self.closed = false

	local p = "data/" .. path

	local chunk = paths.getLua(p)
	if chunk then
		setfenv(chunk, setmetatable(self.variables, chunkMt))
		chunk()
	else
		print("script not found for " .. paths.getPath(p))
		self.closed = true
		return
	end

	p = path
	if not p:endsWith("/") then p = p .. "/" end
	self.variables["SCRIPT_PATH"] = p
	self.variables["close"] = function() self:close() end
	self.variables["state"] = Gamestate.current()
end

function Script:call(func, ...)
	if self.closed then return end

	local f = self.variables[func]
	if f and type(f) == "function" then
		return f(...)
	else
		return nil
	end
end

function Script:callReturn(func, ...)
	if self.closed then return end

	local r = self:call(func, ...)
	if r ~= nil and pcall(function() return type(r) end) then
		return r
	else
		return true
	end
end

function Script:close() self.closed = true end

return Script
