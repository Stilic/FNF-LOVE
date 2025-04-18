
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