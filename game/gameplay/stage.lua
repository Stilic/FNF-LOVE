local Stage = Group:extend()

function Stage:new(name)
	Stage.super.new(self)

	self.name = name

	self.camZoom = 1.05

	self.boyfriendPos = { x = 770, y = 100 }
	self.gfPos = { x = 400, y = 130 }
	self.dadPos = { x = 100, y = 100 }

	self.boyfriendCam = { x = 0, y = 0 }
	self.gfCam = { x = 0, y = 0 }
	self.dadCam = { x = 0, y = 0 }

	local path = "stages/" .. name
	self.script = Script(path)
	self.script.variables["self"] = self

	self.script:call("create")
	self.script:call("postCreate")
end

function Stage:update(dt)
	self.script:call("update", dt)
	Stage.super.update(self, dt)
	self.script:call("postUpdate", dt)
end

function Stage:draw()
	self.script:call("draw")
	Stage.super.draw(self)
	self.script:call("postDraw")
end

function Stage:beat(b)
	self.script:call("beat", b)
	Stage.super.beat(self, b)
	self.script:call("postBeat", b)
end

return Stage
