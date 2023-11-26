local utf8 = require "utf8"

local NumericStepper = Basic:extend()

NumericStepper.instances = {}

local RemoveType = {NONE = 0, DELETE = 1, BACKSPACE = 2}
local CursorDirection = {NONE = 0, LEFT = 1, RIGHT = 2}

-- yeah this is inputtextbox + button

function NumericStepper:new(x, y, stepSize, defaultValue, min, max)
    NumericStepper.super.new(self)

    self.x = x or 0
    self.y = y or 0
    self.width = 40
    self.height = 20
    self.font = love.graphics.getFont()
    self.font:setFilter("nearest", "nearest")
    self.value = type(defaultValue) == "number" and tostring(defaultValue) or
                     "1"
    self.defaultVal = self.value
    self.stepSize = stepSize or 1
    self.min = min or -999
    self.max = max or 999
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
    self.__prevTextWidth = self.font:getWidth(self.value)
    self.__newTextWidth = self.__prevTextWidth

    -- button stepper
    self.onChanged = nil
    self.increaseButton = ui.UIButton(0, 0, self.height, self.height, "+",
                                      function()
        local num = tonumber(self.value)
        local result = num + self.stepSize
        if result > self.max then result = self.max end
        self.value = tostring(result)
        if self.onChanged then self.onChanged(result) end
    end)
    self.decreaseButton = ui.UIButton(0, 0, self.height, self.height, "-",
                                      function()
        local num = tonumber(self.value)
        local result = num - self.stepSize
        if result < self.min then result = self.min end
        self.value = tostring(result)
        if self.onChanged then self.onChanged(result) end
    end)

    table.insert(NumericStepper.instances, self)
end

function NumericStepper:__render(camera)
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
    love.graphics.print(self.value, -self.__scrollTextX,
                        (self.height - self.font:getHeight()) / 2)
    love.graphics.pop()
    love.graphics.setScissor()

    if self.active and true then
        love.graphics.setColor(self.colorCursor)
        love.graphics.rectangle("fill", self.x - self.__scrollTextX + 5 +
                                    self.font:getWidth(
                                        self.value:sub(1, self.__cursorPos)),
                                self.y + 3, 1, self.height - 6)
    end

    self.increaseButton.x = self.x + (self.width * 1.05)
    self.increaseButton.y = self.y
    self.increaseButton:__render(camera)

    self.decreaseButton.x = self.increaseButton.x +
                                (self.increaseButton.width * 1.05)
    self.decreaseButton.y = self.y
    self.decreaseButton:__render(camera)

    love.graphics.setColor(r, g, b, a)
end

function NumericStepper:update(dt)
    if self.active then
        self.__prevTextWidth = self.font:getWidth(self.value)

        if self.value == "" then
            self.value = self.defaultVal
        elseif tonumber(self.value) > self.max then
            self.value = tostring(self.max)
        elseif tonumber(self.value) < self.min then
            self.value = tostring(self.min)
        end

        if self.__input and self.__typing then
            self.__typing = false
            local newText =
                self.value:sub(1, self.__cursorPos) .. self.__input ..
                    self.value:sub(self.__cursorPos + 1)
            self.value = newText
            self.__cursorPos = self.__cursorPos + utf8.len(self.__input)
            self.__input = ""
            if self.onChanged then
                self.onChanged(tonumber(self.value))
            end
        end

        if self.__cursorMove then
            self.__cursorMoveTimer = self.__cursorMoveTimer + dt
            if self.__cursorMoveTimer >= self.__cursorBlinkTime then
                if self.__cursorMoveDir == CursorDirection.LEFT and
                    self.__cursorPos > 0 then
                    self.__cursorPos = self.__cursorPos - 1
                elseif self.__cursorMoveDir == CursorDirection.RIGHT and
                    self.__cursorPos < utf8.len(self.value) then
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
                    local byteoffset = utf8.offset(self.value, -1,
                                                   self.__cursorPos + 1)
                    if byteoffset then
                        self.value =
                            string.sub(self.value, 1, byteoffset - 1) ..
                                string.sub(self.value, byteoffset + 1)
                        self.__cursorPos = self.__cursorPos - 1
                    end
                elseif self.__removeType == RemoveType.DELETE and
                    self.__cursorPos < utf8.len(self.value) then
                    local byteoffset = utf8.offset(self.value, 1,
                                                   self.__cursorPos + 1)
                    if byteoffset then
                        self.value =
                            string.sub(self.value, 1, byteoffset - 1) ..
                                string.sub(self.value, byteoffset + 1)
                    end
                end
                self.__removeTimer = self.__removeTime - 0.02
                if self.onChanged then
                    self.onChanged(tonumber(self.value))
                end
            end
            self.__newTextWidth = self.font:getWidth(self.value)
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
                                self.value:sub(1, self.__cursorPos)) -
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
    self.increaseButton:update(dt)
    self.decreaseButton:update(dt)

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

function NumericStepper:mousepressed(x, y, button, istouch, presses)
    if button == Mouse.LEFT then
        if x >= self.x and x <= self.x + self.width and y >= self.y and y <=
            self.y + self.height then
            self.active = true
            self.__cursorVisible = true

            if self.clearOnPressed then
                self.value = ''
                self.__cursorPos = 0
            end

            self.__cursorPos = utf8.len(self.value)
        else
            self.active = false
            self.__cursorVisible = false
        end
    end
    self.increaseButton:mousepressed(x, y, button, istouch, presses)
    self.decreaseButton:mousepressed(x, y, button, istouch, presses)
end

function NumericStepper:keypressed(key, scancode, isrepeat)
    if self.active then
        if key == "backspace" then
            if self.__cursorPos > 0 then
                local byteoffset = utf8.offset(self.value, -1,
                                               self.__cursorPos + 1)
                if byteoffset then
                    self.value = string.sub(self.value, 1, byteoffset - 1) ..
                                     string.sub(self.value, byteoffset + 1)
                    self.__cursorPos = self.__cursorPos - 1
                end
            end
            self.__removePressed = true
            self.__removeType = RemoveType.BACKSPACE

            self.__newTextWidth = self.font:getWidth(self.value)
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
            if self.onChanged then
                self.onChanged(tonumber(self.value))
            end
        elseif key == "delete" then
            if self.__cursorPos < utf8.len(self.value) then
                local byteoffset = utf8.offset(self.value, 1,
                                               self.__cursorPos + 1)
                if byteoffset then
                    self.value = string.sub(self.value, 1, byteoffset - 1) ..
                                     string.sub(self.value, byteoffset + 1)
                end
            end
            self.__removePressed = true
            self.__removeType = RemoveType.DELETE
            if self.onChanged then
                self.onChanged(tonumber(self.value))
            end
        elseif key == "left" then
            if self.__cursorPos > 0 then
                self.__cursorPos = self.__cursorPos - 1
            end
            self.__cursorMove = true
            self.__cursorMoveDir = CursorDirection.LEFT
        elseif key == "right" then
            if self.__cursorPos < utf8.len(self.value) then
                self.__cursorPos = self.__cursorPos + 1
            end
            self.__cursorMove = true
            self.__cursorMoveDir = CursorDirection.RIGHT
        end
    end
end

function NumericStepper:keyreleased(key, scancode)
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

local function isNumber(str) return string.match(str, "[0123456789%.]+") == str end

function NumericStepper:textinput(text)
    if not self.__removePressed and self.active then
        if isNumber(text) then
            self.__typing = true
            self.__input = self.__input .. text
        end
    end
end

return NumericStepper
