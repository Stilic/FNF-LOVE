local LoadState = State:extend("LoadState")

function LoadState:new(state)
	LoadState.super.new(self)
	self.nextState = state
end

function LoadState:enter()
	self.notCreated = false

	self.script = Script("data/states/load", false)
	local event = self.script:call("create")
	if event == Script.Event_Cancel then
		LoadState.super.enter(self)
		self.notCreated = true
		self.script:call("postCreate")
		return
	end

	self.skipTransIn, self.skipTransOut = true, true

	local px, py = game.width * 0.92, game.height * 0.88
	self.icon = Sprite(0, 0, paths.getImage("menus/loadicon"))
	self.icon:setGraphicSize(self.icon.width * 0.65)
	self.icon:updateHitbox()
	self.icon:setPosition(px - self.icon.width / 2, py - self.icon.height / 2)
	self:add(self.icon)

	local size = math.max(self.icon.width, self.icon.height) + 40
	self.arc = Graphic(0, 0, size, size, Color.WHITE, "arc", "line")
	self.arc:center(self.icon)
	self.arc.line.width = 12
	self.arc.config.segments = 64
	self:add(self.arc)

	self.percent = Text(20, 680, "0%", paths.getFont("vcr.ttf", 16), Color.BLACK)
	self.percent:center(self.icon)
	self.percent.antialiasing = false
	self:add(self.percent)

	self.progress = 0
	self.time = 0

	if game.sound.music then
		game.sound.music:fade(0.66, ClientPrefs.data.menuMusicVolume / 100, 0)
	end

	if self.nextState.preload then self.nextState:preload() end

	paths.threadLoad.start(function()
		if game.sound.music then
			game.sound.music:cancelFade()
		end
		Timer.wait(0.044, function()
			game.switchState(self.nextState)
		end)
	end)

	LoadState.super.enter(self)
	self.script:call("postCreate")
end

function LoadState:update(dt)
	self.script:call("update", dt)
	if self.notCreated then
		LoadState.super.update(self, dt)
		self.script:call("postUpdate", dt)
		return
	end

	local progress = paths.threadLoad.getProgress()
	self.progress = util.coolLerp(self.progress, progress, 24, dt)
	self.time = self.time + dt

	self.arc.config.angle[2] = self.progress * 360
	self.percent.content = math.floor(progress * 100) .. "%"
	self.percent:center(self.icon)

	local amount = math.sin(self.time * 1.8)
	local min = 0.0095
	local scale = min + (1 - min) * math.abs(amount)
	self.icon.scale.x = scale * (amount >= 0 and 1 or -1) * 0.65

	LoadState.super.update(self, dt)
	self.script:call("postUpdate", dt)
end

return LoadState
