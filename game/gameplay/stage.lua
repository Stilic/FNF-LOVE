local Stage = Group:extend()

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

    self.front = Group()

    local path = "stages/" .. name
    self.script = Script(path)
    self.script.variables["self"] = self

    self.script:call("create")
    self.script:call("postCreate")
end

function Stage:update(dt)
    self.script:call("update", dt)
    Stage.super.update(self, dt)
    self.front:update(dt)
    self.script:call("postUpdate", dt)
end

function Stage:draw()
    self.script:call("draw")
    Stage.super.draw(self)
    self.front:draw()
    self.script:call("postDraw")
end

return Stage
