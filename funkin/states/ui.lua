local UIState = State:extend("UIState")

-- for new loxel ui testing
-- Fellyn

function UIState:enter()

    local bg = Sprite()
	bg:loadTexture(paths.getImage('menus/menuDesat'))
	bg.color = {0.15, 0.15, 0.15}
	bg:setScrollFactor()
	self:add(bg)

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
        {"Add Window", function()
            self.windowTest = newUI.UIWindow(0, 0, nil, nil, title)
            self.windowTest:screenCenter()
            self:add(self.windowTest)
        end}
    })
    self:add(self.navbarTest)
end

return UIState