local ButtonManager = {list = {}, active = {}}

function ButtonManager.remap(x, y)
    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(winWidth / game.width, winHeight / game.height)
    return (x - (winWidth - scale * game.width) / 2) / scale,
           (y - (winHeight - scale * game.height) / 2) / scale
end

function ButtonManager.add(o) table.insert(ButtonManager.list, o) end

function ButtonManager.reset()
    for i = #ButtonManager.list, 1, -1 do
        ButtonManager.list[i] = nil
    end
end

function ButtonManager.press(id, x, y)
    local X, Y = ButtonManager.remap(x, y)
    for _, group in ipairs(ButtonManager.list) do
        local pressed = group:checkPress(X, Y)
        if pressed then
            love.keypressed(pressed.key)
            ButtonManager.active[id] = pressed
            pressed.pressed = true
        end
    end
end

function ButtonManager.move(id, x, y)
    local X, Y = ButtonManager.remap(x, y)
    local active = ButtonManager.active[id]

    if not active then
        ButtonManager.press(id, x, y)
    else
        local found = false
        for _, group in ipairs(ButtonManager.list) do
            local pressed = group:checkPress(X, Y)
            if pressed then
                found = true
                if active ~= pressed then
                    love.keyreleased(active.key)
                    active.pressed = false

                    love.keypressed(pressed.key)
                    ButtonManager.active[id] = pressed
                    pressed.pressed = true
                end
            elseif active == pressed then
                pressed.pressed = false
            end
        end

        if not found then
            love.keyreleased(active.key)
            for _, group in ipairs(ButtonManager.list) do
                local pressed = group:checkPress(X, Y)
                if active ~= pressed then
                    active.pressed = false
                end
            end
            ButtonManager.active[id] = nil
        end
    end
end


function ButtonManager.release(id, x, y)
    local X, Y = ButtonManager.remap(x, y)
    local active = ButtonManager.active[id]
    if active then
        for _, group in ipairs(ButtonManager.list) do
            local pressed = group:checkPress(X, Y)
            if pressed then
                love.keyreleased(active.key)
                active.pressed = false
            end
        end
        ButtonManager.active[id] = nil
    end
end

return ButtonManager
