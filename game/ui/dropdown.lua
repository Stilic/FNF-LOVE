local Dropdown = Object:extend()

Dropdown.instances = {}

function Dropdown:new(x, y, options)
    self.x = x
    self.y = y
    self.width = 90
    self.height = 20
    self.options = options
    self.selectedOption = 1
    self.isOpen = false
    self.hovered = false
    self.cameras = nil
    self.font = love.graphics.getFont()
    self.selectedLabel = self.options[1]

    self.__canScroll = false
    self.__curScroll = 0
    self.__maxShow = 10

    self.onChanged = nil

    self.__openButton = ui.UIButton(0, 0, self.height, self.height, "", function()
        self.isOpen = not self.isOpen
    end)

    table.insert(Dropdown.instances, self)
end

function Dropdown:update(dt)
    self.__canScroll = (#self.options > self.__maxShow and true or false)

    if Mouse.wheel ~= 0 and self.__canScroll then
        self.__curScroll = self.__curScroll - Mouse.wheel
        if self.__curScroll < 0 then
            self.__curScroll = 0
        elseif self.__curScroll > #self.options - self.__maxShow then
            self.__curScroll = #self.options - self.__maxShow
        end
    end

    self.__openButton:update(dt)
end

function drawBoid(mode, x, y, length, width , angle)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.rotate(math.rad(angle))
	love.graphics.polygon(mode, -length/2, -width /2, -length/2, width /2, length/2, 0)
	love.graphics.pop()
end

function Dropdown:draw()
    local cameras = self.cameras or Camera.__defaultCameras
    for _, cam in ipairs(cameras) do
        cam:attach()

        if self.isOpen then for i, option in ipairs(self.options) do
            if i > self.__curScroll and i <= (self.__maxShow + self.__curScroll) then
                local fakeIndex = i - self.__curScroll
                local optionX = self.x
                local optionY = self.y + (self.height * fakeIndex)

                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", optionX, optionY, self.width, self.height)
                love.graphics.setColor(0, 0, 0)
                love.graphics.print(option, optionX + 5, optionY + (self.height - self.font:getHeight()) / 2)
                if Mouse.x >= optionX and Mouse.x < optionX + self.width
                    and Mouse.y >= optionY and Mouse.y < optionY + self.height then
                    love.graphics.setColor(0, 0.6, 1)
                    love.graphics.rectangle("fill", optionX, optionY, self.width, self.height)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(option, optionX + 5, optionY + (self.height - self.font:getHeight()) / 2)
                end
            end
        end end

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.selectedLabel, self.x + 5, self.y + (self.height - self.font:getHeight()) / 2)

        self.__openButton.x = self.x + self.width
        self.__openButton.y = self.y
        self.__openButton:draw()

        love.graphics.setColor(1, 1, 1)
        if self.isOpen then
            drawBoid("fill", self.__openButton.x + (self.__openButton.width * 0.49),
                             self.__openButton.y + (self.__openButton.height * 0.49),
                             self.__openButton.width * 0.4,
                             self.__openButton.height * 0.6,
                             -90)
        else
            drawBoid("fill", self.__openButton.x + (self.__openButton.width * 0.49),
                             self.__openButton.y + (self.__openButton.height * 0.49),
                             self.__openButton.width * 0.4,
                             self.__openButton.height * 0.6,
                             90)
        end

        cam:detach()
    end
end

function Dropdown:selectOption(index)
    if index >= 1 and index <= #self.options then
        self.selectedLabel = self.options[index]
        self.selectedOption = index
        self.isOpen = false
        if self.onChanged then self.onChanged(self.selectedLabel) end
    end
end

function isMouseOverOption(self, mx, my)
    if self.isOpen and self.options then
        for i, _ in ipairs(self.options) do
            local optionX = self.x
            local optionY = self.y + (self.height * i)
            if mx >= optionX and mx < optionX + self.width and my >= optionY and my < optionY + self.height then
                return i
            end
        end
    end
end

function Dropdown:mousepressed(x, y, button)
    local optionClicked = isMouseOverOption(self, x, y)
    if self.isOpen and optionClicked then
        self:selectOption(optionClicked + self.__curScroll)
    end
    self.__openButton:mousepressed(x, y, button)
end

return Dropdown
