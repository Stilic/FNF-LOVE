---@class Script:Classic
local Script = Classic:extend("Script")

local chunkMt = {__index = _G}
local closedenv = setmetatable({}, {
	__index = function() error("closed") end,
	__newindex = function() error("closed") end,
})

Script.Event_Continue = 1
Script.Event_Cancel = 2

function Script:new(path, notFoundMsg)
	self.path = path
	self.variables = {}
	self.notFoundMsg = (notFoundMsg == nil and true or false)
	self.closed = false
	self.chunk = nil

	local s, err = pcall(function()
		local p, vars = path, self.variables

		local chunk = paths.getLua(p)
		if chunk then
			setfenv(chunk, setmetatable(vars, chunkMt))
			chunk()
		else
			if not self.notFoundMsg then return end
			print("script not found for " .. paths.getPath(p))
			self.closed = true
			return
		end

		if not p:endsWith("/") then p = p .. "/" end
		vars.close = function() self:close() end
		vars.Event_Continue = Script.Event_Continue
		vars.Event_Cancel = Script.Event_Cancel
		vars.SCRIPT_PATH = Script.p
		vars.state = game.getState()

		self.chunk = chunk
	end)

	if not s then
		print('oh no script is returning an error NOOOO: ' .. err)
		self.closed = true
	end
end

function Script:set(var, value)
	if self.closed then return end

	self.variables[var] = value
end

function Script:call(func, ...)
	if self.closed then return true end
	local f = self.variables[func]
	if f and type(f) == "function" then
		local s, err = pcall(f, ...)
		if s then
			if err ~= nil and pcall(type, err) then
				return err
			end
			return true
		else
			print('oh no script is returning an error at ' ..
				func .. " NOOOO: " .. err)
			self.closed = true
		end
	end
	return nil
end

function Script:close()
	if self.variables then table.clear(self.variables) end
	if self.chunk then setfenv(self.chunk, closedenv) end
	self.closed = true
	self.variables = nil
	self.chunk = nil
end

return Script
