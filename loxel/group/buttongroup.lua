-- Children Function
local function tranformChildren(self, func, value)
    if self.group == nil then return end

    for _, button in ipairs(self.__graphics) do
        if button ~= nil then func(button, value) end
    end
end

local function xTransform(button, x) button.x = button.x + x end
local function yTransform(button, y) button.y = button.y + y end
local function wTransform(button, w) button.width = w end
local function hTransform(button, h) button.height = h end
local function angleTransform(button, angle) button.angle = button.angle + angle end
local function alphaTransform(button, alpha) button.alpha = alpha end
local function camerasTransform(button, cameras) button.cameras = cameras end
local function fillTransform(button, fill) button.fill = fill end
local function typeTransform(button, type) button.type = type end
local function lineWidthTransform(button, lineWidth) button.line.width = lineWidth end
local function linedTransform(button, lined) button.lined = lined end
local function stunnedTransform(button, stunned) button.stunned = stunned end

--------------

---@class ButtonGroup:Button
local ButtonGroup = Button:extend("ButtonGroup")

function ButtonGroup:new()
    ButtonGroup.super.new(self)

    self.__x = self.x
    self.__y = self.y
    self.__width = self.width
    self.__height = self.height
    self.__angle = self.angle

    self.__alpha = alpha
    self.__fill = self.fill
    self.__type = self.type

    self.__stunned = self.stunned

    self.__lined = self.lined
    self.line.__width = self.line.width

    self.group = Group()
    self.__graphics = self.group.members
end

function ButtonGroup:add(button)
    return self.group:add(button)
end

function ButtonGroup:update(dt)
    if self.__cameras ~= self.cameras then
        tranformChildren(self, camerasTransform, self.cameras)
        self.__cameras = self.cameras
    end
    if self.__stunned ~= self.stunned then
        transformChildren(self, stunnedTransform, self.stunned)
        self.__stunned = self.stunned
    end
    if self.__x ~= self.x then
        tranformChildren(self, xTransform, self.x - self.__x)
        self.__x = self.x
    end
    if self.__y ~= self.y then
        tranformChildren(self, yTransform, self.y - self.__y)
        self.__y = self.y
    end
    if self.__width ~= self.width then
        tranformChildren(self, wTransform, self.width)
        self.__width = self.width
    end
    if self.__height ~= self.height then
        tranformChildren(self, hTransform, self.height)
        self.__height = self.height
    end
    if self.__angle ~= self.angle then
        tranformChildren(self, angleTransform, self.angle - self.__angle)
        self.__angle = self.angle
    end
    if self.__alpha ~= self.alpha then
        tranformChildren(self, alphaTransform, self.alpha)
        self.__alpha = self.alpha
    end
    if self.__fill ~= self.fill then
        tranformChildren(self, fillTransform, self.fill)
        self.__fill = self.fill
    end
    if self.__type ~= self.type then
        tranformChildren(self, typeTransform, self.type)
        self.__type = self.type
    end
    if self.__lined ~= self.lined then
        tranformChildren(self, linedTransform, self.lined)
        self.__lined = self.lined
    end
    if self.line.__width ~= self.line.width then
        tranformChildren(self, lineWidthTransform, self.line.width)
        self.line.__width = self.line.width
    end
    self.group:update(dt)
end

function ButtonGroup:draw()
    self.group:draw()
end

function ButtonGroup:checkPress(x, y)
    if not self.stunned then
        for _, button in ipairs(self.__graphics) do
            if not button.stunned and x >= button.x and
                x <= button.x + button.width and y >= button.y and
                y <= button.y + button.height then
                return button
            end
        end
    end
    return nil
end

return ButtonGroup