
function create()
    self.camZoom = 0.9

    self.dadPos = {x = 200, y = 100}
    self.gfPos = {x = 480, y = 130}
    self.boyfriendPos = {x = 1100, y = 100}

    local test = ParallaxImage(100, 100, 1280, 720)
    test.offsetBack = {x = 0, y = -300}
    test.offsetFront = {x = 0, y = -150}
    test.scrollFactorBack = {x = 0.4, y = 0.4}
    test.scrollFactorFront = {x = 1.2, y = 1.2}
    test.scaleBack = 1.5
    test.scaleFront = 1.8
    self:add(test)

    local testF = ParallaxImage(100, 440, 1280, 100)
    testF.color = {0.7, 0.7, 0.7}
    testF.offsetBack = {x = 0, y = -530}
    testF.offsetFront = {x = 0, y = -500}
    testF.scrollFactorBack = {x = 1.2, y = 1.2}
    testF.scrollFactorFront = {x = 1.1, y = 1.1}
    testF.scaleBack = 1.8
    testF.scaleFront = 1.7
    self:add(testF)
end

function postCreate() game.camera.bgColor = {0.5, 0.5, 0.5} end
