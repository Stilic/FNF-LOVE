-- Children Function
local function tranformChildren(self, func, value)
    for i, grp in ipairs(self.group) do
        if grp.name == self.tabs[self.selectedTab] then
            for j, obj in ipairs(grp.members) do
                if obj ~= nil then func(obj, value) end
            end
        end
    end
end
local function callChildren(self, func, ...)
    for i, grp in ipairs(self.group) do
        if grp.name == self.tabs[self.selectedTab] then
            for j, obj in ipairs(grp.members) do
                if obj[func] then obj[func](obj, ...) end
            end
        end
    end
end
local function xTransform(obj, x) obj.x = obj.x + x end
local function yTransform(obj, y) obj.y = obj.y + y end

-----------------------------------------------------------------------------------------------

local TabMenu = Object:extend()

function TabMenu:new(x, y, tabs, font)
    self.x = x
    self.y = y
    self.tabs = tabs
    self.group = {}
    self.selectedTab = 1
    self.font = font or love.graphics.getFont()
    self.width = 380
    self.height = 480
    self.tabHeight = 20

    self.cameras = nil

    self.__x = self.x
    self.__y = self.y
end

function TabMenu:addGroup(group)
    for i, obj in ipairs(group.members) do
        obj.x = obj.x + self.x
        obj.y = obj.y + (self.y + self.tabHeight)
    end
    table.insert(self.group, group)
end
function TabMenu:removeGroup(group)
    for i, grp in ipairs(self.group) do
        if grp == group then table.remove(self.group, i) end
    end
end

function TabMenu:update(dt)
    if Mouse.justPressed then
        if Mouse.justPressedLeft then
            self:mousepressed(Mouse.x, Mouse.y, 1)
        elseif Mouse.justPressedRight then
            self:mousepressed(Mouse.x, Mouse.y, 2)
        elseif Mouse.justPressedMiddle then
            self:mousepressed(Mouse.x, Mouse.y, 3)
        end
    end
    if Mouse.justReleased then
        if Mouse.justReleasedLeft then
            self:mousereleased(Mouse.x, Mouse.y, 1)
        elseif Mouse.justReleasedRight then
            self:mousereleased(Mouse.x, Mouse.y, 2)
        elseif Mouse.justReleasedMiddle then
            self:mousereleased(Mouse.x, Mouse.y, 3)
        end
    end
    if self.__x ~= self.x then
        tranformChildren(self, xTransform, self.x - self.__x)
        self.__x = self.x
    end
    if self.__y ~= self.y then
        tranformChildren(self, yTransform, self.y - self.__y)
        self.__y = self.y
    end
    if self.tabs then callChildren(self, 'update', dt) end
end

function TabMenu:draw()
    for _, c in ipairs(self.cameras or Camera.__defaultCameras) do
        if c.visible and c.exists then
            table.insert(c.__renderQueue, self)
        end
    end
end

function TabMenu:__render()
    local r, g, b, a = love.graphics.getColor()

    if self.tabs then
        for i, tab in ipairs(self.tabs) do
            local tabX = self.x + (i - 1) * ((self.width / #self.tabs) + 2)
            local tabY = self.y
            local tabColor = (i == self.selectedTab) and {0.5, 0.5, 0.5} or
                                 {0.3, 0.3, 0.3}

            love.graphics.setColor(tabColor)
            love.graphics.rectangle("fill", tabX, tabY,
                                    (self.width / #self.tabs), self.tabHeight)

            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("line", tabX, tabY,
                                    (self.width / #self.tabs), self.tabHeight)

            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.font)
            local textWidth = self.font:getWidth(tab)
            local textHeight = self.font:getHeight(tab)
            love.graphics.print(tab, tabX +
                                    ((self.width / #self.tabs) - textWidth) / 2,
                                tabY + (self.tabHeight - textHeight) / 2)
        end
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", self.x, self.y + self.tabHeight,
                            self.width + (#self.tabs + 3), self.height)

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", self.x, self.y + self.tabHeight,
                            self.width + (#self.tabs + 3), self.height)

    if self.tabs then callChildren(self, 'draw') end

    love.graphics.setColor(r, g, b, a)
end

function TabMenu:selectTab(index)
    if index >= 1 and index <= #self.tabs then self.selectedTab = index end
end

local function isMouseOverTab(self, mx, my)
    if self.tabs then
        for i, _ in ipairs(self.tabs) do
            local tabX = self.x + (i - 1) * ((self.width / #self.tabs) + 2)
            local tabY = self.y
            if mx >= tabX and mx <= tabX + (self.width / #self.tabs) and my >=
                tabY and my <= tabY + self.tabHeight then return i end
        end
    end

    return nil
end

function TabMenu:mousepressed(x, y, button)
    local tabClicked = isMouseOverTab(self, x, y)
    if tabClicked then self:selectTab(tabClicked) end
    if self.tabs then callChildren(self, 'mousepressed', x, y, button) end
end
function TabMenu:mousemoved(x, y, dx, dy, istouch)
    if self.tabs then callChildren(self, 'mousemoved', x, y, dx, dy, istouch) end
end
function TabMenu:mousereleased(x, y, button, istouch, presses)
    if self.tabs then
        callChildren(self, 'mousereleased', x, y, button, istouch, presses)
    end
end

function TabMenu:keypressed(key, scancode, isrepeat)
    if self.tabs then
        callChildren(self, 'keypressed', key, scancode, isrepeat)
    end
end
function TabMenu:keyreleased(key, scancode)
    if self.tabs then callChildren(self, 'keyreleased', key, scancode) end
end
function TabMenu:textinput(text)
    if self.tabs then callChildren(self, 'textinput', text) end
end

return TabMenu
