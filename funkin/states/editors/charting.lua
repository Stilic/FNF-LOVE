local encodeJson = (require 'lib.json').encode

local ChartingState = State:extend("ChartingState")

ChartingState.startPos = 0
ChartingState.sustainColors = {
	{194, 75, 153}, {0, 255, 255}, {8, 250, 5}, {249, 57, 63}
}

function ChartingState:enter()
	love.mouse.setVisible(true)
end

function ChartingState:update(dt)
	if game.keys.justPressed.ENTER then
		game.sound.music:stop()
		if self.vocals then self.vocals:stop() end

		PlayState.chartingMode = true
		PlayState.startPos = game.keys.pressed.CONTROL and 0 or 0
		game.switchState(PlayState())
	end

	if game.keys.justPressed.BACKSPACE then
		game.sound.music:stop()
		if self.vocals then self.vocals:stop() end

		PlayState.chartingMode = false
		PlayState.startPos = 0
		game.sound.playMusic(paths.getMusic("freakyMenu"))
		game.switchState(FreeplayState())
	end
end

return ChartingState