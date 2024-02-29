local UIState = State:extend("UIState")

-- for new loxel ui testing
-- Fellyn

function UIState:enter()

    local bg = Sprite()
	bg:loadTexture(paths.getImage('menus/menuDesat'))
	bg.color = {0.15, 0.15, 0.15}
	bg:setScrollFactor()
	self:add(bg)

    self.uiList = {}

    self.navbarTest = newUI.UINavbar({
        {"File", function()
            if self.windowTest ~= nil then
                self.windowTest.title = 'File!'
            end
            game.sound.play(paths.getSound("beep"))
        end},
        {"Edit", function()
            if self.windowTest ~= nil then
                self.windowTest.title = 'Edit!'
            end
            game.sound.play(paths.getSound("beep"))
        end},
        {"View", function()
            if self.windowTest ~= nil then
                self.windowTest.title = 'View!'
            end
            game.sound.play(paths.getSound("beep"))
        end},
        {"Help", function()
            if self.windowTest ~= nil then
                self.windowTest.title = 'Help!'
            end
            game.sound.play(paths.getSound("beep"))
        end},
        {"Window", function()
            self:add_UIWindow()
            game.sound.play(paths.getSound("beep"))
        end}
    })
    self:add(self.navbarTest)

    table.insert(self.uiList, self.navbarTest)
end

function UIState:add_UIWindow()
    if self.windowTest then
        if not self.windowTest.alive then
            self.windowTest:revive()
        else
            self.windowTest:kill()
        end
    else
        self.windowTest = newUI.UIWindow(0, 0, nil, nil, title)
        self.windowTest:screenCenter()
        self:add(self.windowTest)
        table.insert(self.uiList, self.windowTest)

        self.checkboxTest = newUI.UICheckbox(10, 10, 20)
        self.windowTest:add(self.checkboxTest)
    end
end

-- still confused about hovered ui
function UIState:checkHovered()
    local ret = false
    for i = #self.uiList, 1, -1 do
        local u = self.uiList[i]
        u.active = true
        if u.hovered and i == #self.uiList then
            ret = true
        else
            u.active = false
        end
    end
    return ret
end

function UIState:update(dt)
    UIState.super.update(self, dt)

    --[[local hovered = self:checkHovered()
    print(hovered)

    if self.windowTest and self.navbarTest then
        print('window ' .. tostring(self.windowTest.hovered) .. ' | navbar ' .. tostring(self.navbarTest.hovered))
    end]]
end

return UIState