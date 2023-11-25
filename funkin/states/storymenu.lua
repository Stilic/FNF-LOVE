local StoryMenuState = State:extend()

StoryMenuState.curWeek = 1

function StoryMenuState:enter()
    paths.clearCache()

    PlayState.storyMode = true

    game.camera.bgColor = {0.2, 0.2, 0.2}

    game.camera.scroll = {x = 0, y = 0}

    local bgYellow = Sprite(0, 56):make(game.width, 386, Color.fromRGB(249, 207, 81))

    local blackBar = Sprite():make(game.width, 56, Color.BLACK)
    self:add(blackBar)

    self:add(bgYellow)
end

function StoryMenuState:update(dt)
    StoryMenuState.super.update(self, dt)

    if Keyboard.pressed.J then
        game.camera.scroll.x = game.camera.scroll.x - 2
    elseif Keyboard.pressed.L then
        game.camera.scroll.x = game.camera.scroll.x + 2
    end
    if Keyboard.pressed.I then
        game.camera.scroll.y = game.camera.scroll.y - 2
    elseif Keyboard.pressed.K then
        game.camera.scroll.y = game.camera.scroll.y + 2
    end

    if controls:pressed("back") then
        game.sound.play(paths.getSound("cancelMenu"))
        game.switchState(MainMenuState())
    end
end

function StoryMenuState:leave()
    game.camera.bgColor = {0, 0, 0}
end

return StoryMenuState