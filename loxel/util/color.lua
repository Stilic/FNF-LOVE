local Color = {
    WHITE = {1, 1, 1},
    BLACK = {0, 0, 0},
    RED = {1, 0, 0},
    GREEN = {0, 1, 0},
    BLUE = {0, 0, 1}
}

function Color.fromRGB(r, g, b) return {r/255, g/255, b/255} end

return Color