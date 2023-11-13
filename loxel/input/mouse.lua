local Mouse = {
    LEFT = 1,
    RIGHT = 2,
    MIDDLE = 3,

    wheel = 0,
    x = 0,
    y = 0,
    screenX = 0,
    screenY = 0,

    isMoved = false,

    justPressed = false,
    justPressedLeft = false,
    justPressedRight = false,
    justPressedMiddle = false,

    pressed = false,
    pressedLeft = false,
    pressedRight = false,
    pressedMiddle = false,

    justReleased = false,
    justReleasedLeft = false,
    justReleasedRight = false,
    justReleasedMiddle = false,

    released = true,
    releasedLeft = true,
    releasedRight = true,
    releasedMiddle = true
}

function Mouse.update()
    if Mouse.wheel ~= 0 then Mouse.wheel = 0 end
    if Mouse.isMoved then Mouse.isMoved = false end
    if Mouse.justPressed then
        Mouse.justPressed = false
        Mouse.justPressedLeft = false
        Mouse.justPressedRight = false
        Mouse.justPressedMiddle = false
    end
    if Mouse.justReleased then
        Mouse.justReleased = false
        Mouse.justReleasedLeft = false
        Mouse.justReleaseddRight = false
        Mouse.justReleasedMiddle = false
    end
end

function Mouse.overlaps(obj)
    if obj and obj:is(Group) then
        for _, o in ipairs(obj.members) do
            if o and (o.x and o.y and o.width and o.height) then
                Mouse.overlaps(o)
            end
        end
    elseif obj and obj:is(Sprite) then
        return (Mouse.x >= obj.x and Mouse.x <= obj.x + obj.width and Mouse.y >=
                   obj.y and Mouse.y <= obj.y + obj.height)
    end
    return false
end

function Mouse.onPressed(button)
    if button == Mouse.LEFT then
        Mouse.justPressedLeft = true
        Mouse.pressedLeft = true
        Mouse.justReleasedLeft = false
        Mouse.releasedLeft = false
    elseif button == Mouse.RIGHT then
        Mouse.justPressedRight = true
        Mouse.pressedRight = true
        Mouse.justReleasedRight = false
        Mouse.releasedRight = false
    elseif button == Mouse.MIDDLE then
        Mouse.justPressedMiddle = true
        Mouse.pressedMiddle = true
        Mouse.justReleasedMiddle = false
        Mouse.releasedMiddle = false
    end
    Mouse.justPressed = true
    Mouse.pressed = true
    Mouse.justReleased = false
    Mouse.released = false
end

function Mouse.onReleased(button)
    if button == Mouse.LEFT then
        Mouse.justPressedLeft = false
        Mouse.pressedLeft = false
        Mouse.justReleasedLeft = true
        Mouse.releasedLeft = true
    elseif button == Mouse.RIGHT then
        Mouse.justPressedRight = false
        Mouse.pressedRight = false
        Mouse.justReleasedRight = true
        Mouse.releasedRight = true
    elseif button == Mouse.MIDDLE then
        Mouse.justPressedMiddle = false
        Mouse.pressedMiddle = false
        Mouse.justReleasedMiddle = true
        Mouse.releasedMiddle = true
    end
    Mouse.justPressed = false
    Mouse.pressed = false
    Mouse.justReleased = true
    Mouse.released = true
end

function Mouse.onMoved(x, y)
    local winWidth, winHeight = love.graphics.getDimensions()
    local scale = math.min(winWidth / game.width, winHeight / game.height)
    Mouse.x, Mouse.y = (x - (winWidth - scale * game.width) / 2) / scale,
                       (y - (winHeight - scale * game.height) / 2) / scale

    Mouse.screenX, Mouse.screenY = x, y
    Mouse.isMoved = true
end

return Mouse
