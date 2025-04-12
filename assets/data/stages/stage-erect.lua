function create()
    self.camZoom = 0.85

    local offY = -700

    --self.boyfriendPos = {x=977.5,y=865+offY}
    --self.dadPos = {x=40,y=850+offY}
    --self.gfPos = {x=501.5, y=825+offY}

    local backDark = Sprite(729, -170):loadTexture(paths.getImage(SCRIPT_PATH.."backDark"))
    self:add(backDark)
    
    local brightLightSmall = Sprite(967, -103):loadTexture(paths.getImage(SCRIPT_PATH.."brightLightSmall"))
    brightLightSmall:setScrollFactor(1.2, 1.2)
    brightLightSmall.blend = 'add'
    self:add(brightLightSmall)

    local crowd = Sprite(560, 290)
    crowd:setFrames(paths.getSparrowAtlas(SCRIPT_PATH.."crowd"))
    crowd:addAnimByPrefix("idle", "Symbol 2 instance 1", 12)
    crowd:play("idle")
    crowd:setScrollFactor(0.8, 0.8)
    self:add(crowd)

    local bg = Sprite(-603, -187):loadTexture(paths.getImage(SCRIPT_PATH.."bg"))
    self:add(bg)

    local server = Sprite(-361, 205):loadTexture(paths.getImage(SCRIPT_PATH.."server"))
    self:add(server)

    local lights = Sprite(-601, -147):loadTexture(paths.getImage(SCRIPT_PATH.."lights"))
    lights:setScrollFactor(1.2,1.2)
    self:add(lights, true)

    local orangeLight = Sprite(189, -195):loadTexture(paths.getImage(SCRIPT_PATH.."orangeLight"))
    self:add(orangeLight)
    local lightgreen = Sprite(-171, 242):loadTexture(paths.getImage(SCRIPT_PATH.."lightgreen"))
    self:add(lightgreen)
    local lightred = Sprite(-101, 560):loadTexture(paths.getImage(SCRIPT_PATH.."lightred"))
    self:add(lightred)

    local lightAbove = Sprite(804, -117):loadTexture(paths.getImage(SCRIPT_PATH.."lightAbove"))
    self:add(lightAbove, true)
end

function postCreate()
    local colorShaderBf = Shader('adjustColor')
    local colorShaderDad = Shader('adjustColor')
    local colorShaderGf = Shader('adjustColor')

    colorShaderBf.brightness = -23
    colorShaderBf.hue = 12
    colorShaderBf.contrast = 7
	colorShaderBf.saturation = 0

    colorShaderGf.brightness = -30
    colorShaderGf.hue = -9
    colorShaderGf.contrast = -4
	colorShaderGf.saturation = 0

    colorShaderDad.brightness = -33
    colorShaderDad.hue = -32
    colorShaderDad.contrast = -23
	colorShaderDad.saturation = 0

    state.boyfriend.shader = colorShaderBf:get()
    state.dad.shader = colorShaderDad:get()
    state.gf.shader = colorShaderGf:get()

    close()
end