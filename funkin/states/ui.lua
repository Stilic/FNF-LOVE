local State = loxel.State
local Sprite = loxel.Sprite

local UINavbar = loxel.ui.UINavbar
local UIwindow = loxel.ui.UIWindow
local UICheckbox = loxel.ui.UICheckbox
local UISlider = loxel.ui.UISlider

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

    self.navbarTest = UINavbar({
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
        self.windowTest = UIWindow(0, 0, nil, nil, title)
        self.windowTest:screenCenter()
        self:add(self.windowTest)
        table.insert(self.uiList, self.windowTest)

        self.checkboxTest = UICheckbox(10, 10, 20)
        self.windowTest:add(self.checkboxTest)

        self.sliderTest = UISlider(10, 80, 150, 10, 0, "horizontal")
        self.windowTest:add(self.sliderTest)
    end
end

return UIState