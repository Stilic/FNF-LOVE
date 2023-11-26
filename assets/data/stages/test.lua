function create()
    self.camZoom = 0.9

    self.dadPos = {x = 200, y = 100}
    self.gfPos = {x = 480, y = 130}
    self.boyfriendPos = {x = 1100, y = 100}

    local ground = ParallaxImage(100, 100, 1280, 720,
                                 paths.getImage('menus/menuDesat'))
    ground.offsetBack = {x = 0, y = -300}
    ground.offsetFront = {x = 0, y = -150}
    ground.scrollFactorBack = {x = 0.4, y = 0.4}
    ground.scrollFactorFront = {x = 1.2, y = 1.2}
    ground.scaleBack = 1.5
    ground.scaleFront = 1.8
    self:add(ground)
end

function postCreate()
    game.camera.bgColor = {0.5, 0.5, 0.5}
    close()
end
