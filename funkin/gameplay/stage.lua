local Stage = Group:extend("Stage")

function Stage.preload(name)
	if name ~= "" then
		local path = "stages/" .. name
		local script = Script("data/" .. path)
		script:set("SCRIPT_PATH", path .. "/")
		local list = script:call("preload")
		if list and type(list) == "table" then
			paths.threadLoad.add(list)
		end
		script:close()
	end
end

function Stage:new(name)
	Stage.super.new(self)

	self.name = name

	self.camZoom, self.camSpeed, self.camZoomSpeed = 1.1, 1, 1

	self.boyfriendPos = {x = 770, y = 100}
	self.gfPos = {x = 400, y = 130}
	self.dadPos = {x = 100, y = 100}

	self.boyfriendCam = {x = 0, y = 0}
	self.gfCam = {x = 0, y = 0}
	self.dadCam = {x = 0, y = 0}

	self.foreground = Group()

	if name ~= "" then
		local path = "stages/" .. name
		self.script = Script("data/" .. path)
		self.script:set("SCRIPT_PATH", path .. "/")
		self.script:linkObject(self)
		self.script:set("self", self)

		self.script:call("create")
	end
end

function Stage:add(obj, foreground)
	if foreground then
		self.foreground:add(obj)
	else
		Stage.super.add(self, obj)
	end
end

return Stage
