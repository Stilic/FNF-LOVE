local ParallaxImage = Basic:extend()

function ParallaxImage:new(x, y, width, height)
    ParallaxImage.super.new(self)

    if x == nil then x = 0 end
    if y == nil then y = 0 end
    self.x = x
    self.y = y

    self.width = width
    self.height = height

    local vertices = {
        {0, 0, 0, 0},
        {self.width, 0, 1, 0},
        {self.width, self.height, 1, 1},
        {0, self.height, 0, 1}
    }

    self.offsetBack = {x = 0, y = 0}
    self.offsetFront = {x = 0, y = 0}

    self.scrollFactorBack = {x = 1, y = 1}
    self.scrollFactorFront = {x = 1, y = 1}

    self.scaleBack = 1
    self.scaleFront = 1

    self.color = {1, 1, 1}

    self.mesh = love.graphics.newMesh(vertices, "fan")
    self.mesh:setTexture(paths.getImage('menus/mainmenu/menuDesat'))
end

function ParallaxImage:draw()
    ParallaxImage.super.draw(self)
end

function ParallaxImage:__render(camera)
    local xBack, yBack = self.x, self.y
    xBack, yBack = xBack - (camera.scroll.x * self.scrollFactorBack.x),
           yBack - (camera.scroll.y * self.scrollFactorBack.y)

    local xFront, yFront = self.x, self.y
    xFront, yFront = xFront - (camera.scroll.x * self.scrollFactorFront.x),
            yFront - (camera.scroll.y * self.scrollFactorFront.y)

    xBack = xBack + self.width / 2
    xFront = xFront + self.width / 2

    local vertices = {{
            (-self.width*self.scaleBack/2) + xBack - self.offsetBack.x,
            yBack - self.offsetBack.y,
            0,
            0
        },{
            (-self.width*self.scaleBack/2) + xBack + (self.width*self.scaleBack) -
                                                      self.offsetBack.x,
            yBack - self.offsetBack.y,
            1,
            0
        },{
            (-self.width*self.scaleFront/2) + xFront + (self.width*self.scaleFront) -
                                                        self.offsetFront.x,
            yFront + self.height - self.offsetFront.y,
            1,
            1
        },{
            (-self.width*self.scaleFront/2) + xFront - self.offsetFront.x,
            yFront + self.height - self.offsetFront.y,
            0,
            1
    }}
    self.mesh:setVertices(vertices)

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])

    love.graphics.draw(self.mesh, 0, 0)

    love.graphics.setColor(r, g, b, a)
end

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

function postCreate()
    game.camera.bgColor = {0.5, 0.5, 0.5}
end
