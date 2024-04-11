local Stage = Group:extend("Stage")

function Stage:new(name)
	Stage.super.new(self)

	self.name = name

	self.camZoom = 1.05
	self.camSpeed = 1

	self.boyfriendPos = {x = 770, y = 100}
	self.gfPos = {x = 400, y = 130}
	self.dadPos = {x = 100, y = 100}

	self.boyfriendCam = {x = 0, y = 0}
	self.gfCam = {x = 0, y = 0}
	self.dadCam = {x = 0, y = 0}

	self.ratingPos = {x = 658, y = 444}

	self.foreground = Group()

	local path = "stages/" .. name
	self.script = Script("data/" .. path)
	self.script:set("SCRIPT_PATH", path .. "/")
	self.script:set("self", self)

	self.script:call("create")
end

function Stage:add(obj, foreground)
	if foreground then
		self.foreground:add(obj)
	else
		Stage.super.add(self, obj)
	end
end

return Stage
