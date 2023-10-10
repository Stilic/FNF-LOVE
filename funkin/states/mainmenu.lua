local MainMenuState = State:extend()

MainMenuState.curSelected = 1

function MainMenuState:enter()
    self.optionShit = {'story_mode', 'freeplay', 'donate', 'options'}

    self.selectedSomethin = false

    self.camScroll = Camera()
    self.camScroll.target = {x = 0, y = 0}
    game.cameras.reset(self.camScroll)

    local yScroll = math.max(0.25 - (0.05 * (#self.optionShit - 4)), 0.1)
    self.menuBg = Sprite()
    self.menuBg:loadTexture(paths.getImage('menus/mainmenu/menuBG'))
    self.menuBg:setScrollFactor(0, yScroll)
    self.menuBg:setGraphicSize(math.floor(self.menuBg.width * 1.175))
    self.menuBg:updateHitbox()
    self.menuBg:screenCenter()
    self:add(self.menuBg)

    self.magentaBg = Sprite()
    self.magentaBg:loadTexture(paths.getImage('menus/mainmenu/menuBGMagenta'))
    self.magentaBg.visible = false
    self.magentaBg:setScrollFactor(0, yScroll)
    self.magentaBg:setGraphicSize(math.floor(self.magentaBg.width * 1.175))
    self.magentaBg:updateHitbox()
    self.magentaBg:screenCenter()
    self:add(self.magentaBg)

    self.menuItems = Group()
    self:add(self.menuItems)

    local scale = 1
    for i = 0, #self.optionShit - 1 do
        local offset = 98 - (math.max(#self.optionShit, 4) - 4) * 80
        local menuItem = Sprite(0, (i * 140) + offset)
        menuItem.scale = {x = scale, y = scale}
        menuItem:setFrames(paths.getSparrowAtlas(
                               'menus/mainmenu/menuoptions/menu_' ..
                                   self.optionShit[i + 1]))
        menuItem:addAnimByPrefix('idle', self.optionShit[i + 1] .. ' basic', 24)
        menuItem:addAnimByPrefix('selected', self.optionShit[i + 1] .. ' white',
                                 24)
        menuItem:play('idle')
        menuItem.ID = (i + 1)
        menuItem:screenCenter('x')
        self.menuItems:add(menuItem)
        local scr = (#self.optionShit - 4) * 0.135
        if #self.optionShit < 6 then scr = 0 end
        menuItem:setScrollFactor(0, scr)
        menuItem:updateHitbox()
    end

    self.camFollow = {x = 0, y = 0}

    self.daText = Text(12, game.height - 24, "FNF-LOVE v0.5",
                       paths.getFont("vcr.ttf", 16), {255, 255, 255})
    self.daText.outWidth = 2
    self.daText:setScrollFactor()
    self:add(self.daText)

    -- funny popup
    self.gf_popup = SpriteGroup(game.width - 460, game.height)
    self.gf_popup:setScrollFactor()

    local popup_bg = Sprite(100)
    popup_bg:make(350, 130, {0, 0, 0})
    popup_bg.alpha = 0.7

    local wip_text = Text(116, 34, 'Work In\nProgress..',
                          paths.getFont("vcr.ttf", 34), {255, 255, 255})
    local gf_icon = HealthIcon('gf', true)
    gf_icon.x = 150
    self.gf_popup:add(popup_bg)
    self.gf_popup:add(wip_text)
    self.gf_popup:add(gf_icon)

    self:add(self.gf_popup)
    self.popupAppears = false

    self:changeSelection()
end

function MainMenuState:update(dt)
    self.camScroll.target.x, self.camScroll.target.y = util.coolLerp(
                                                           self.camScroll.target
                                                               .x,
                                                           self.camFollow.x, 1),
                                                       util.coolLerp(
                                                           self.camScroll.target
                                                               .y,
                                                           self.camFollow.y, 1)

    if not self.selectedSomethin then
        if controls:pressed('ui_up') then self:changeSelection(-1) end
        if controls:pressed('ui_down') then self:changeSelection(1) end

        if controls:pressed("back") then
            game.sound.play(paths.getSound('cancelMenu'))
            switchState(TitleState())
        end

        if controls:pressed("accept") then
            local selected = self.optionShit[MainMenuState.curSelected]
            if selected == 'donate' then
                love.system.openURL('https://ninja-muffin24.itch.io/funkin')
            elseif not self.popupAppears and selected == 'story_mode' or
                selected == 'options' then
                self.popupAppears = true
                game.sound.play(paths.getSound('gameplay/GF_' ..
                                                   love.math.random(1, 4)))
                game.sound.play(paths.getSound('gameplay/ANGRY'))
                game.camera:shake(0.003, 0.2)

                Timer.tween(0.5, self.gf_popup, {y = game.height - 140},
                            "out-cubic", function()
                    Timer.after(1.5, function()
                        Timer.tween(0.5, self.gf_popup, {y = game.height},
                                    "in-cubic",
                                    function()
                            self.popupAppears = false
                        end)
                    end)
                end)
            elseif selected == 'freeplay' then
                self.selectedSomethin = true
                game.sound.play(paths.getSound('confirmMenu'))

                Flicker(self.magentaBg, 1.1, 0.15, false)

                for i, spr in ipairs(self.menuItems.members) do
                    if MainMenuState.curSelected ~= spr.ID then
                        Timer.tween(0.4, spr, {alpha = 0}, 'out-quad',
                                    function()
                            spr:destroy()
                        end)
                    else
                        Flicker(spr, 1, 0.06, false, false, function()
                            local daChoice =
                                self.optionShit[MainMenuState.curSelected]

                            if daChoice == 'story_mode' then
                                --
                            elseif daChoice == 'freeplay' then
                                switchState(FreeplayState())
                            elseif daChoice == 'options' then
                                --
                            end
                        end)
                    end
                end
            end
        end
    end

    MainMenuState.super.update(self, dt)

    for _, spr in ipairs(self.menuItems.members) do spr:screenCenter('x') end
end

function MainMenuState:changeSelection(huh)
    if huh == nil then huh = 0 end
    game.sound.play(paths.getSound('scrollMenu'))

    MainMenuState.curSelected = MainMenuState.curSelected + huh

    if MainMenuState.curSelected > #self.optionShit then
        MainMenuState.curSelected = 1
    elseif MainMenuState.curSelected < 1 then
        MainMenuState.curSelected = #self.optionShit
    end

    for _, spr in ipairs(self.menuItems.members) do
        spr:play('idle')
        spr:updateHitbox()

        if spr.ID == MainMenuState.curSelected then
            spr:play('selected')
            local add = 0
            if #self.menuItems > 4 then add = #self.menuItems * 8 end
            local x, y = spr:getGraphicMidpoint()
            self.camFollow.x, self.camFollow.y = x, y - add
            spr:centerOffsets()
        end
    end
end

return MainMenuState
