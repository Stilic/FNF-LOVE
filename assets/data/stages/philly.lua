function create()
    local bg = Sprite(-100)
    bg:loadTexture(paths.getImage(SCRIPT_PATH .. 'sky'))
    bg:setScrollFactor(0.1, 0.1)
    self:add(bg)

    local city = Sprite(-10)
    city:loadTexture(paths.getImage(SCRIPT_PATH .. 'city'))
    city:setScrollFactor(0.3, 0.3)
	city:setGraphicSize(math.floor(city.width * 0.85))
	city:updateHitbox()
	self:add(city)

    lightColors = {{49, 162, 253}, {49, 253, 140}, {251, 51, 245}, {253, 69, 49}, {251, 166, 51}}
    curLight = 1

    phillyWindow = Sprite(city.x)
    phillyWindow:loadTexture(paths.getImage(SCRIPT_PATH .. 'window'))
	phillyWindow:setScrollFactor(0.3, 0.3)
	phillyWindow.alpha = 0
	phillyWindow:setGraphicSize(math.floor(phillyWindow.width * 0.85))
	phillyWindow:updateHitbox()
    self:add(phillyWindow)

    local streetBehind = Sprite(-40, 50)
    streetBehind:loadTexture(paths.getImage(SCRIPT_PATH .. 'behindTrain'))
	self:add(streetBehind)

    trainMoving = false
    trainFrameTiming = 0
    trainCars = 8
    trainFinishing = false
    trainCooldown = 0

    startedMoving = false

    phillyTrain = Sprite(2000, 360)
    phillyTrain:loadTexture(paths.getImage(SCRIPT_PATH .. 'train'))
	self:add(phillyTrain)

    trainSound = Sound(paths.getSound('gameplay/train_passes'))

    local street = Sprite(-40, streetBehind.y)
    street:loadTexture(paths.getImage(SCRIPT_PATH .. 'street'))
	self:add(street)
end

function update(dt)
    phillyWindow.alpha = phillyWindow.alpha - (PlayState.inst.crochet / 1000) * dt * 1.5

    if trainMoving then
        trainFrameTiming = trainFrameTiming + dt

		if trainFrameTiming >= 1 / 24 then
			if trainSound.__source:tell() >= 4.7 then
                startedMoving = true
                state.gf:playAnim('hairBlow')
				--state.gf.specialAnim = true
            end

            if startedMoving then
                phillyTrain.x = phillyTrain.x - 400

                if phillyTrain.x < -2000 and not trainFinishing then
                    phillyTrain.x = -1150
                    trainCars = trainCars - 1

                    if trainCars <= 0 then
                        trainFinishing = true
                    end
                end

                if phillyTrain.x < -4000 and trainFinishing then
                    state.gf.danced = false -- Sets head to the correct position once the animation ends
			        state.gf:playAnim('hairFall')
                    phillyTrain.x = game.width + 200
                    trainMoving = false
                    trainCars = 8
                    trainFinishing = false
                    startedMoving = false
                end
            end

            trainFrameTiming = 0
        end
    end
end

function beat(b)
    if not trainMoving then
        trainCooldown = trainCooldown + 1
    end

    if b % 4 == 0 then
        curLight = love.math.random(1, #lightColors)
        phillyWindow.color = {lightColors[curLight][1]/255,
                              lightColors[curLight][2]/255,
                              lightColors[curLight][3]/255}
        phillyWindow.alpha = 1
    end

    if b % 8 == 4 and love.math.randomBool(30) and not trainMoving and trainCooldown > 8 then
        trainCooldown = love.math.random(-4, 0)
        trainMoving = true
        if not trainSound.__source:isPlaying() then
            trainSound:play()
        end
    end
end