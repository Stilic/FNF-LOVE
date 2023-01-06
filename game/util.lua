local util = {}

function util.round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end

function util.bound(value, min, max) return math.max(min, math.min(max, value)) end

function util.lerp(a, b, c) return a + util.bound(c, 0, 1) * (b - a) end

function util.startsWith(str, start) return string.sub(str, 1, #start) == start end

function util.endsWith(str, ending)
    return ending == "" or string.sub(str, -#ending) == ending
end

function util.newGradient(dir, ...)
    local isHorizontal = true
    if dir == "vertical" then
        isHorizontal = false
    elseif dir ~= "horizontal" then
        error("bad argument #1 to 'gradient' (invalid value)", 2)
    end

    local colorLen = select("#", ...)
    if colorLen < 2 then error("color list is less than two", 2) end

    local meshData = {}
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

return util
