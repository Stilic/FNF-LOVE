local LoadScreen = require "funkin.ui.loadscreen"
local LoadState = State:extend("LoadState")

function LoadState:new(state)
	LoadState.super.new(self)
	self.nextState = state
end

function LoadState:enter()
	self.skipTransIn, self.skipTransOut = true, true
	self.load = LoadScreen(self.nextState)
	self:add(self.load)

	LoadState.super.enter(self)
end

function LoadState:update(dt)
	if paths.async.getProgress() == 1 and not self._loaded then
		self._loaded = true
		if game.sound.music then
			game.sound.music:cancelFade()
		end
		Timer.wait(0.044, function()
			game.switchState(self.nextState)
		end)
	end
	LoadState.super.update(self, dt)
end

return LoadState
