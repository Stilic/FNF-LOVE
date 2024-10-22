local Shader = Classic:extend("Shader")
Shader.instances = {}

local function fileExists(path)
	path = paths.getPath("shaders/" .. path)
	return path, paths.exists(path, "file")
end

function Shader:new(source)
	rawset(self, "uniforms", {})

	local fragPath, fragExists = fileExists(source .. ".frag")
	local vertPath, vertExists = fileExists(source .. ".vert")

	if fragExists or vertExists then
		rawset(self, "_shader", love.graphics.newShader(
			fragExists and fragPath or nil,
			vertExists and vertPath or nil))
	else
		rawset(self, "_shader", love.graphics.newShader(source))
	end

	local haveTime = self._shader:hasUniform("time")
	if haveTime then
		rawset(self, "__time", 0)
	end

	table.insert(Shader.instances, self)
end

function Shader:update(dt)
	if self.__time then
		rawset(self, "__time", self.__time + dt)
		self:set("time", self.__time)
	end
end

function Shader:__newindex(key, value)
	if type(value) == "function" then
		rawset(self, key, value)
	else
		if not rawget(self, "_shader") or not self._shader:hasUniform(key) then
			print("Shader uniform " .. key .. " is not defined")
			if not rawget(self, "_shader") then
				print("Shader doesn't exists (?)")
			end
			return false
		end
		self:set(key, value)
	end
end

function Shader:set(name, value)
	if self.uniforms[name] == value then return end
	rawset(self.uniforms, name, value)
	self._shader:send(name, value)
end

function Shader:get() return rawget(self, "_shader") end

function Shader:destroy()
	self._shader:release()
	rawset(self, "_shader", nil)

	Shader.instances[self] = nil
end

function Shader.updateTime(dt)
	for _, shader in pairs(Shader.instances) do
		shader:update(dt)
	end
end

function Shader.clear()
	for _, shader in pairs(Shader.instances) do
		shader:destroy()
	end
	Shader.instances = {}
end

return Shader
