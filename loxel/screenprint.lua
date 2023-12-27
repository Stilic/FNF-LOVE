local function makePopup(x, y, w, h, r)
    if r == nil then r = {20, 20} end
    -- https://gist.github.com/gvx/9072860
    local v = {}
    local precision = (r[1] + r[2]) * 0.18
    local angle = math.rad(90)
    if r[1] > w * 0.5 then r[1] = w * 0.5 end
    if r[2] > h * 0.5 then r[2] = h * 0.5 end

    local x1, y1, x2, y2 = x + r[1], y + r[2],
                           x + w - r[1], y + h - r[2]

    local sin, cos = math.sin, math.cos
    for i = 0, precision do
        local a = (i / precision - 1) * angle
        table.insert(v, x2 + r[1] * cos(a))
        table.insert(v, y1 + r[2] * sin(a))
    end
    for i = 0, precision do
        local a = (i / precision) * angle
        table.insert(v, x2 + r[1] * cos(a))
        table.insert(v, y2 + r[2] * sin(a))
    end
    for i = 0, precision do
        local a = (i / precision + 1) * angle
        table.insert(v, x1 + r[1] * cos(a))
        table.insert(v, y2 + r[2] * sin(a))
    end
    for i = 0, precision do
        local a = (i / precision + 2) * angle
        table.insert(v, x1 + r[1] * cos(a))
        table.insert(v, y1 + r[2] * sin(a))
    end
    local r, g, b, a = love.graphics.getColor()
    love.graphics.polygon("fill", v)
    love.graphics.setColor(r + 0.2, g + 0.2, b + 0.2)
    love.graphics.polygon("line", v)
    love.graphics.setColor(r, g, b, a)
end

local ScreenPrint = {prints = {}, game = {width = 0, height = 0}}

function ScreenPrint.init(width, height)
    ScreenPrint.game.width = width
    ScreenPrint.game.height = height
end

function ScreenPrint.new(text, font)
    local print = {
        text = text,
        font = (font or love.graphics.getFont()),
        height = 0,
        bg = {
            x = 0,
            y = ScreenPrint.game.height,
            width = math.min(ScreenPrint.game.width - 72, font:getWidth(text) + 36),
            height = 0,
            offset = {x = 0, y = 0},
            color = {0.2, 0.2, 0.25}
        },
        timer = math.max(2, (string.len(text) * 0.03))
    }

    local _, wt = print.font:getWrap(print.text, print.bg.width - 36)
    print.bg.x = (love.graphics.getWidth() - print.bg.width) / 2
    print.bg.height = print.font:getHeight() * #wt + 36
    print.bg.y = print.bg.y + print.bg.height
    print.height = print.font:getHeight() * #wt

    table.insert(ScreenPrint.prints, print)
end

function ScreenPrint.update(dt)
    for i = #ScreenPrint.prints, 1, -1 do
        local print = ScreenPrint.prints[i]
        print.timer = print.timer - dt

        if print.timer > 0 then
            print.bg.y = util.coolLerp(print.bg.y,
                                       ScreenPrint.game.height - 15 - print.bg.height, 0.2)
        else
            print.bg.y = util.coolLerp(print.bg.y,
                                       ScreenPrint.game.height + print.bg.height + 5, 0.1)
        end
 
        if print.bg.y >= ScreenPrint.game.height + print.bg.height and print.timer < 0 then
            table.delete(ScreenPrint.prints, print)
        end
    end
end

function ScreenPrint.draw()
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    for _, print in ipairs(ScreenPrint.prints) do
        local x, y = print.bg.x - print.bg.offset.x, print.bg.y - print.bg.offset.y
        love.graphics.setColor(print.bg.color)
        makePopup(x, y, print.bg.width, print.bg.height)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(print.font)

        local center = (print.bg.height - print.height) / 2
        love.graphics.printf(print.text, x + (36 / 2), y + center,
                             print.bg.width - 36)
    end
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

return ScreenPrint
