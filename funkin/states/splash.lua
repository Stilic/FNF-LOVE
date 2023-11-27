local Splash = State:extend()

function Splash:enter()
    if Application.splashScreen then
        Timer.after(1, function() self:startSplash() end)
    else
        game.switchState(TitleState())
    end
end

function Splash:startSplash()
    self.funkinLogo = Sprite():loadTexture(
                        paths.getImage('menus/splashScreen/FNFLOVE_logo'))
    self.funkinLogo.scale = {x = 0.7, y = 0.7}
    self.funkinLogo.visible = false
    self.funkinLogo:updateHitbox()
    self.funkinLogo:screenCenter()
    self:add(self.funkinLogo)

    self.funkinLogoBump = Sprite():loadTexture(
                        paths.getImage('menus/splashScreen/FNFLOVE_logo'))
    self.funkinLogoBump.scale = {x = 0.7, y = 0.7}
    self.funkinLogoBump.visible = false
    self.funkinLogoBump:updateHitbox()
    self.funkinLogoBump:screenCenter()
    self:add(self.funkinLogoBump)

    self.stilicIcon = HealthIcon('stilic')
    self.stilicIcon.scale = {x = 1.8, y = 1.8}
    self.stilicIcon.visible = false
    self.stilicIcon:updateHitbox()
    self.stilicIcon:screenCenter()
    self:add(self.stilicIcon)

    self.poweredBy = Text(0, game.height * 0.9, 'Powered by ',
                            paths.getFont('phantommuff.ttf', 24))
    self.poweredBy.visible = false
    self.poweredBy:screenCenter('x')
    self.poweredBy.x = self.poweredBy.x - 12
    self:add(self.poweredBy)

    self.love2d = Sprite(self.poweredBy.x + self.poweredBy:getWidth(), game.height * 0.885)
    self.love2d:loadTexture(paths.getImage('menus/splashScreen/love2d'))
    self.love2d.scale = {x = 0.17, y = 0.17}
    self.love2d.visible = false
    self:add(self.love2d)

    Timer.script(function(setTimer)
        self.funkinLogo.alpha = 0
        self.funkinLogo.visible = true
        Timer.tween(5, self.funkinLogo.scale, {x = 0.65, y = 0.65})
        Timer.tween(0.1, self.funkinLogo, {alpha = 1})
        self.funkinLogoBump.alpha = 0.5
        self.funkinLogoBump.visible = true
        Timer.tween(1, self.funkinLogoBump.scale, {x = 1.4, y = 1.4}, 'out-sine')
        Timer.tween(1, self.funkinLogoBump, {alpha = 0}, 'out-sine')

        setTimer(2)

        self.poweredBy.alpha = 0
        self.poweredBy.visible = true
        self.love2d.alpha = 0
        self.love2d.visible = true
        Timer.tween(0.5, self.poweredBy, {alpha = 1})
        Timer.tween(0.5, self.love2d, {alpha = 1})

        setTimer(2)

        self.funkinLogo.visible = true
        self.stilicIcon.alpha = 0
        self.stilicIcon.visible = true
        Timer.tween(1, self.funkinLogo, {alpha = 0})
        Timer.tween(6, self.stilicIcon.scale, {x = 1.5, y = 1.5})
        Timer.tween(1, self.stilicIcon, {alpha = 1})

        setTimer(2)

        Timer.tween(0.5, self.poweredBy, {alpha = 0})
        Timer.tween(0.5, self.love2d, {alpha = 0})

        setTimer(2)

        Timer.tween(1, self.stilicIcon, {alpha = 0})
    end)

    game.sound.play(paths.getMusic('titleShoot'), 0.5, false, true, function()
        game.switchState(TitleState())
    end)
end

return Splash