local p = .65
local l = 0.04 * (1 / p + 1) * p

local realCamScX = 0
local realCamScY = 0

local camScX = 0
local camScY = 0

function postCreate()
    realCamScX = state.camGame.target.x
    realCamScY = state.camGame.target.y

    camScX = realCamScX
    camScY = realCamScY
end

function update()
    state.camGame.target.x = state.camGame.target.x - (camScX - realCamScX)
    state.camGame.target.y = state.camGame.target.y - (camScY - realCamScY)
end

function postUpdate()
    realCamScX = state.camGame.target.x
    realCamScY = state.camGame.target.y

    camScX = math.lerp(camScX, realCamScX, l)
    camScY = math.lerp(camScY, realCamScY, l)

    state.camGame.target.x = camScX
    state.camGame.target.y = camScY
end
