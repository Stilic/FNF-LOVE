local InputTextBox = Basic:extend("InputTextBox")

InputTextBox.instances = {}

local RemoveType = {NONE = 0, DELETE = 1, BACKSPACE = 2}
local CursorDirection = {NONE = 0, LEFT = 1, RIGHT = 2}

function InputTextBox:new(x, y, width, height, font)
	InputTextBox.super.new(self)

	self.x = x or 0
	self.y = y or 0
	self.width = width or 100
	self.height = height or 20
	self.font = font or love.graphics.getFont()
	self.font:setFilter("nearest", "nearest")
	self.text = ""
	self.active = false
	self.colorText = {0, 0, 0}
	self.color = {1, 1, 1}
	self.colorBorder = {0, 0, 0}
	self.colorCursor = {0, 0, 0}
	self.clearOnPressed = false

	-- add text
	self.__input = ""
	self.__typing = false

	-- cursor
	self.__cursorPos = 0
	self.__cursorBlinkTime = 0.5
	self.__cursorBlinkTimer = 0
	self.__cursorVisible = false
	self.__cursorMove = false
	self.__cursorMoveTime = 0.5
	self.__cursorMoveTimer = 0
	self.__cursorMoveDir = CursorDirection.NONE

	-- remove text
	self.__removeTime = 0.5
	self.__removeTimer = 0
	self.__removePressed = false
	self.__removeType = RemoveType.NONE

	-- scrolling text
	self.__scrollTextX = 0

	-- uhh
	self.__prevTextWidth = self.font:getWidth(self.text)
	self.__newTextWidth = self.__prevTextWidth

	self.onChanged = nil

	table.insert(InputTextBox.instances, self)
end

function InputTextBox:__render()
	local r, g, b, a = love.graphics.getColor()

	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
	love.graphics.setColor(self.colorBorder)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

	love.graphics.setColor(1, 1, 1)
	love.graphics.push()
	love.graphics.translate(self.x + 5, self.y)
	love.graphics.setScissor(self.x, self.y, self.width - 10, self.height)

	love.graphics.setColor(self.colorText)
	love.graphics.setFont(self.font)
	love.graphics.print(self.text, -self.__scrollTextX,
		(self.height - self.font:getHeight()) / 2)
	love.graphics.pop()
	love.graphics.setScissor()

	if self.active and true then
		love.graphics.setColor(self.colorCursor)
		love.graphics.rectangle("fill", self.x - self.__scrollTextX + 5 +
			self.font:getWidth(
				self.text:sub(1, self.__cursorPos)),
			self.y + 3, 1, self.height - 6)
	end

	love.graphics.setColor(r, g, b, a)
end

function InputTextBox:update(dt)
	if self.active then
		self.__prevTextWidth = self.font:getWidth(self.text)

		if self.__input and self.__typing then
			self.__typing = false
			local newText =
				self.text:sub(1, self.__cursorPos) .. self.__input ..
				self.text:sub(self.__cursorPos + 1)
			self.text = newText
			self.__cursorPos = self.__cursorPos + utf8.len(self.__input)
			self.__input = ""
			if self.onChanged then self.onChanged(self.text) end
		end

		if self.__cursorMove then
			self.__cursorMoveTimer = self.__cursorMoveTimer + dt
			if self.__cursorMoveTimer >= self.__cursorBlinkTime then
				if self.__cursorMoveDir == CursorDirection.LEFT and
					self.__cursorPos > 0 then
					self.__cursorPos = self.__cursorPos - 1
				elseif self.__cursorMoveDir == CursorDirection.RIGHT and
					self.__cursorPos < utf8.len(self.text) then
					self.__cursorPos = self.__cursorPos + 1
				end
				self.__cursorMoveTimer = self.__cursorBlinkTime - 0.02
			end
		end

		if self.__removePressed then
			self.__removeTimer = self.__removeTimer + dt
			if self.__removeTimer >= self.__removeTime then
				if self.__removeType == RemoveType.BACKSPACE and
					self.__cursorPos > 0 then
					local byteoffset = utf8.offset(self.text, -1,
						self.__cursorPos + 1)
					if byteoffset then
						self.text = string.sub(self.text, 1, byteoffset - 1) ..
							string.sub(self.text, byteoffset + 1)
						self.__cursorPos = self.__cursorPos - 1
					end
				elseif self.__removeType == RemoveType.DELETE and
					self.__cursorPos < utf8.len(self.text) then
					local byteoffset = utf8.offset(self.text, 1,
						self.__cursorPos + 1)
					if byteoffset then
						self.text = string.sub(self.text, 1, byteoffset - 1) ..
							string.sub(self.text, byteoffset + 1)
					end
				end
				self.__removeTimer = self.__removeTime - 0.02
				if self.onChanged then self.onChanged(self.text) end
			end
			self.__newTextWidth = self.font:getWidth(self.text)
			if self.__newTextWidth > self.__prevTextWidth then
				self.__scrollTextX = math.max(
					self.__scrollTextX -
					(self.__newTextWidth -
						self.__prevTextWidth), 0)
			elseif self.__newTextWidth < self.__prevTextWidth and
				self.__scrollTextX > 0 then
				self.__scrollTextX = math.min(
					self.__scrollTextX +
					(self.__prevTextWidth -
						self.__newTextWidth),
					self.__prevTextWidth -
					(self.width - 10))
			end
		end

		self.__cursorBlinkTimer = self.__cursorBlinkTimer + dt
		if self.__cursorBlinkTimer >= self.__cursorBlinkTime then
			self.__cursorVisible = not self.__cursorVisible
			self.__cursorBlinkTimer = 0
		end

		local cursorX = self.x + 5 +
			self.font:getWidth(
				self.text:sub(1, self.__cursorPos)) -
			self.__scrollTextX
		if cursorX > self.x + self.width - 10 then
			self.__scrollTextX = self.__scrollTextX +
				(cursorX - (self.x + self.width - 10))
		elseif cursorX < self.x + 5 then
			self.__scrollTextX = self.__scrollTextX - (self.x + 5 - cursorX)
		elseif self.__scrollTextX < 0 then
			self.__scrollTextX = 0
		end
	end

	if Mouse.justPressed then
		if Mouse.justPressedLeft then
			self:mousepressed(Mouse.x, Mouse.y, Mouse.LEFT)
		elseif Mouse.justPressedRight then
			self:mousepressed(Mouse.x, Mouse.y, Mouse.RIGHT)
		elseif Mouse.justPressedMiddle then
			self:mousepressed(Mouse.x, Mouse.y, Mouse.MIDDLE)
		end
	end
end

function InputTextBox:mousepressed(x, y, button, istouch, presses)
	if button == Mouse.LEFT then
		if x >= self.x and x <= self.x + self.width and y >= self.y and y <=
			self.y + self.height then
			self.active = true
			self.__cursorVisible = true

			if self.clearOnPressed then
				self.text = ''
				self.__cursorPos = 0
			end

			self.__cursorPos = utf8.len(self.text)
		else
			self.active = false
			self.__cursorVisible = false
		end
	end
end

function InputTextBox:keypressed(key, scancode, isrepeat)
	if self.active then
		if key == "backspace" then
			if self.__cursorPos > 0 then
				local byteoffset = utf8.offset(self.text, -1,
					self.__cursorPos + 1)
				if byteoffset then
					self.text = string.sub(self.text, 1, byteoffset - 1) ..
						string.sub(self.text, byteoffset + 1)
					self.__cursorPos = self.__cursorPos - 1
				end
			end
			self.__removePressed = true
			self.__removeType = RemoveType.BACKSPACE

			self.__newTextWidth = self.font:getWidth(self.text)
			if self.__newTextWidth > self.__prevTextWidth then
				self.__scrollTextX = math.max(
					self.__scrollTextX -
					(self.__newTextWidth -
						self.__prevTextWidth), 0)
			elseif self.__newTextWidth < self.__prevTextWidth and
				self.__scrollTextX > 0 then
				self.__scrollTextX = math.min(
					self.__scrollTextX +
					(self.__prevTextWidth -
						self.__newTextWidth),
					self.__prevTextWidth -
					(self.width - 10))
			end
			if self.onChanged then self.onChanged(self.text) end
		elseif key == "delete" then
			if self.__cursorPos < utf8.len(self.text) then
				local byteoffset = utf8.offset(self.text, 1,
					self.__cursorPos + 1)
				if byteoffset then
					self.text = string.sub(self.text, 1, byteoffset - 1) ..
						string.sub(self.text, byteoffset + 1)
				end
			end
			self.__removePressed = true
			self.__removeType = RemoveType.DELETE
			if self.onChanged then self.onChanged(self.text) end
		elseif key == "left" then
			if self.__cursorPos > 0 then
				self.__cursorPos = self.__cursorPos - 1
			end
			self.__cursorMove = true
			self.__cursorMoveDir = CursorDirection.LEFT
		elseif key == "right" then
			if self.__cursorPos < utf8.len(self.text) then
				self.__cursorPos = self.__cursorPos + 1
			end
			self.__cursorMove = true
			self.__cursorMoveDir = CursorDirection.RIGHT
		end
	end
end

function InputTextBox:keyreleased(key, scancode)
	if key == "backspace" or key == "delete" then
		self.__removePressed = false
		self.__removeTimer = 0
		self.__removeType = RemoveType.NONE
	end
	if key == "left" or key == "right" then
		self.__cursorMove = false
		self.__cursorMoveTimer = 0
		self.__cursorMoveDir = CursorDirection.NONE
	end
end

function InputTextBox:textinput(text)
	if not self.__removePressed and self.active then
		self.__typing = true
		self.__input = self.__input .. text
	end
end

return InputTextBox
