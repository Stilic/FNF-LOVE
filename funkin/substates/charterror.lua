local ChartErrorSubstate = Substate:extend("ChartErrorSubstate")

function ChartErrorSubstate:new(songpath)
	ChartErrorSubstate.super.new(self)

	self.exit = false

	local listPaths = {}
	switch(type(songpath), {
		['string'] = function () table.insert(listPaths, songpath) end,
		['table'] = function () listPaths = songpath end
	})

	self.bg = Graphic(0, 0, game.width, game.height, {0, 0, 0})
	self.bg.alpha = 0
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.titleTxt = Alphabet(0, -80, #listPaths .. ' Chart(s) Not Found', true, false)
	self.titleTxt:screenCenter('x')
	self:add(self.titleTxt)

	self.listTxt = Text(20, 720, "", paths.getFont('phantommuff.ttf', 30))
	self:add(self.listTxt)
	for i = 1, #listPaths do
		self.listTxt.content = self.listTxt.content .. '- ' .. listPaths[i] .. '\n'
	end

	self.continueTxt = Text(0, game.height * 0.94, "BACK / ACCEPT to continue",
		paths.getFont('phantommuff.ttf', 30))
	self.continueTxt:screenCenter('x')
	self.continueTxt.alpha = 0
	self:add(self.continueTxt)
end

function ChartErrorSubstate:enter()
	game.sound.play(paths.getSound('gameplay/missnote' .. love.math.random(1, 3)))
	Timer.tween(0.4, self.bg, {alpha = 0.6}, 'in-out-quart')
	Timer.tween(0.4, self.titleTxt, {y = 40}, 'out-quart')
	Timer.tween(0.4, self.listTxt, {y = 140}, 'out-quart')
	Timer.tween(0.4, self.continueTxt, {alpha = 1}, 'out-quart')
end

function ChartErrorSubstate:update(dt)
	ChartErrorSubstate.super.update(self, dt)

	if not self.exit then
		if controls:pressed('accept') or controls:pressed('back') then
			self.exit = true

			Timer.cancelTweensOf(self.continueTxt)
			Timer.cancelTweensOf(self.listTxt)
			Timer.cancelTweensOf(self.titleTxt)
			Timer.cancelTweensOf(self.bg)

			Timer.tween(0.4, self.continueTxt, {alpha = 0}, 'in-quart')
			Timer.tween(0.4, self.listTxt, {y = 720}, 'in-quart')
			Timer.tween(0.4, self.titleTxt, {y = -80}, 'in-quart')
			Timer.tween(0.4, self.bg, {alpha = 0}, 'in-out-quart', function ()
				self:close()
			end)
		end
	end
end

return ChartErrorSubstate
