local grpLimoDancers
local limo
local fastCar

function create()
    self.camZoom = 0.9

    self.boyfriendPos = {x = 1030, y = -120}
    self.boyfriendCam = {x = -200, y = 0}

    local skyBG = Sprite(-120, -50)
    skyBG:loadTexture(paths.getImage(SCRIPT_PATH .. 'limoSunset'))
    skyBG:setScrollFactor(0.1, 0.1)
    self:add(skyBG)

    local bgLimo = Sprite(-200, 480)
    bgLimo:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'bgLimo'))
    bgLimo:addAnimByPrefix('drive', "background limo pink", 24)
    bgLimo:play('drive')
    bgLimo:setScrollFactor(0.4, 0.4)
    self:add(bgLimo)

    grpLimoDancers = Group()
    self:add(grpLimoDancers)

    for i = 0, 4 do
        local dancer = BackgroundDancer((370 * i) + 130, bgLimo.y - 400)
        dancer:setScrollFactor(0.4, 0.4)
        grpLimoDancers:add(dancer)
    end

    limo = Sprite(-120, 550)
    limo:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'limoDrive'))
    limo:addAnimByPrefix('drive', "Limo stage", 24)
    limo:play('drive')

    fastCar = Sprite(-300, 160)
    fastCar:loadTexture(paths.getImage(SCRIPT_PATH .. 'fastCarLol'))
    fastCar.moves = true
    self.foreground:add(fastCar)
    resetFastCar()
end

function postCreate()
    table.insert(state.members, table.find(state.members, state.gf)+1, limo)
end

local updateElapsed = 0
function update(dt) updateElapsed = dt end

local fastCarCanDrive = true
local fastCarSpeed = 170
function resetFastCar()
    fastCarSpeed = love.math.random(170, 220)
    fastCar.x = -12600 - (fastCarSpeed*32)
	fastCar.y = love.math.random(140, 250)
	fastCar.velocity.x = 0
	fastCarCanDrive = true
end

function fastCarDrive()
    game.sound.play(paths.getSound('gameplay/carPass' .. love.math.random(0, 1)), 0.7)

    fastCar.velocity.x = (fastCarSpeed / updateElapsed)
	fastCarCanDrive = false
    Timer.after(2, function() resetFastCar() end)
end

function beat()
    for _, spr in pairs(grpLimoDancers.members) do
        spr:dance()
    end
    if love.math.randomBool(10) and fastCarCanDrive then
        fastCarDrive()
    end
end