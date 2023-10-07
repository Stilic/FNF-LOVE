local util = {}

function util.coolLerp(x, y, i)
    return math.lerp(x, y, 1 - 1 / math.exp(i * 60 * love.timer.getDelta()))
end

function util.floorDecimal(value, decimals)
    if decimals < 1 then
        return math.floor(value)
    end

    local tempMult = 1
    for i = 1, decimals do
        tempMult = tempMult * 10
    end
    local newValue = math.floor(value * tempMult)
    return newValue / tempMult
end

function util.remapToGame(x, y)
    local scale = {}
    local offset = {}

    local dw, dh
    local ww, wh = love.graphics.getDimensions()
    scale.x = ww / game.width
    scale.y = wh / game.height

    local sv = math.min(scale.x, scale.y)
    if sv >= 1 then
        sv = math.floor(sv)
    end

    offset.x = math.floor((scale.x - sv) * (game.width / 2))
    offset.y = math.floor((scale.y - sv) * (game.height / 2))

    scale.x, scale.y = sv, sv

    dw = ww - offset.x * 2
    dh = wh - offset.y * 2

    local nx, ny
    x, y = x - offset.x, y - offset.y
    nx, ny = x / dw, y / dh

    x = (x >= 0 and x <= game.width * scale.x) and math.floor(nx * game.width) or - 1
    y = (y >= 0 and y <= game.height * scale.y) and math.floor(ny * game.height) or - 1

    return x, y
end

function util.newGradient(dir, ...)
    local isHorizontal = true
    if dir == "vertical" then isHorizontal = false end

    local colorLen, meshData = select("#", ...), {}
    if isHorizontal then
        for i = 1, colorLen do
            local color = select(i, ...)
            local x = (i - 1) / (colorLen - 1)

            meshData[#meshData + 1] = {
                x, 1, x, 1, color[1], color[2], color[3], color[4] or 1
            }
            meshData[#meshData + 1] = {
                x, 0, x, 0, color[1], color[2], color[3], color[4] or 1
            }
        end
    else
        for i = 1, colorLen do
            local color = select(i, ...)
            local y = (i - 1) / (colorLen - 1)

            meshData[#meshData + 1] = {
                1, y, 1, y, color[1], color[2], color[3], color[4] or 1
            }
            meshData[#meshData + 1] = {
                0, y, 0, y, color[1], color[2], color[3], color[4] or 1
            }
        end
    end

    return love.graphics.newMesh(meshData, "strip", "static")
end

function util.removeExtension(filename)
    local nameWithoutExt = filename:match("(.+)%..+$")
    if nameWithoutExt then
        return nameWithoutExt
    else
        return filename
    end
end

return util
