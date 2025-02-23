local SearchBox = SpriteGroup:extend("SearchBox")

function SearchBox:new(x, y, width, height)
	SearchBox.super.new(self, x, y)
	self.hovered = false
	self.focus = false

	self.box = Graphic(0, 0, width, height, Color.BLACK)
	self.box.alpha = 0.5
	self:add(self.box)

	self.text = ""

	self.textObj = Text(10, 10, "", paths.getFont("vcr.ttf", 18), Color.WHITE, "left", width - 20)
	self:add(self.textObj)

	TextInput:add(bind(self, self.textInput))
	game.keys.onPress:add(function(key)
		if key == "BACKSPACE" then
			self:backspace()
		end
	end)
	love.keyboard.setTextInput(false)
	love.keyboard.setKeyRepeat(false)
end

function SearchBox:update(dt)
	SearchBox.super.update(self, dt)

	local mx, my = game.mouse.x, game.mouse.y
	self.hovered =
		(mx >= self.x and mx <= self.box.x + self.box.width and my >= self.y and my <=
			self.y + self.box.height)

	if game.mouse.justPressed then
		self.focus = self.hovered
		love.keyboard.setTextInput(self.focus)
	end
end

function SearchBox:backspace()
	if self.focus then
		local offset = utf8.offset(self.text, -1)

		if offset then
			self.text = string.sub(self.text, 1, offset - 1)
			self.textObj.content = self.text
		end
	end
end

function SearchBox:textInput(t)
	self.text = self.text .. t
	self.textObj.content = self.text
end

return SearchBox
