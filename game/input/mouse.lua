local Mouse = Object:extend()

Mouse.wheel = 0
Mouse.x = 0
Mouse.y = 0
Mouse.screenX = 0
Mouse.screenY = 0

Mouse.isMoved = false

Mouse.justPressed = false
Mouse.justPressedLeft = false
Mouse.justPressedRight = false
Mouse.justPressedMiddle = false

Mouse.pressed = false
Mouse.pressedLeft = false
Mouse.pressedRight = false
Mouse.pressedMiddle = false

Mouse.justReleased = false
Mouse.justReleasedLeft = false
Mouse.justReleasedRight = false
Mouse.justReleasedMiddle = false

Mouse.released = false
Mouse.releasedLeft = false
Mouse.releasedRight = false
Mouse.releasedMiddle = false

local LEFT = 1
local RIGHT = 2
local MIDDLE = 3

function Mouse:update()
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

function Mouse:init()
    Mouse.released = true
    Mouse.releasedLeft = true
    Mouse.releasedRight = true
    Mouse.releasedMiddle = true
end

function Mouse.overlaps(obj)
    if obj and obj:is(Group) then
        for _, o in ipairs(obj.members) do
            if o and (o.x and o.y and o.width and o.height) then
                return (Mouse.x >= o.x and Mouse.x <= o.x + o.width and
                        Mouse.y >= o.y and myMouse.y <= o.y + o.height)
            end
        end
    elseif obj and obj:is(Sprite) then
        return (Mouse.x >= obj.x and Mouse.x <= obj.x + obj.width and
                Mouse.y >= obj.y and myMouse.y <= obj.y + obj.height)
    end
    return false
end

function Mouse.onPressed(x, y, button)
    if button == LEFT then
        Mouse.justPressedLeft = true
        Mouse.pressedLeft = true
        Mouse.justReleasedLeft = false
        Mouse.releasedLeft = false
    elseif button == RIGHT then
        Mouse.justPressedRight = true
        Mouse.pressedRight = true
        Mouse.justReleasedRight = false
        Mouse.releasedRight = false
    elseif button == MIDDLE then
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

function Mouse.onReleased(x, y, button)
    if button == LEFT then
        Mouse.justPressedLeft = false
        Mouse.pressedLeft = false
        Mouse.justReleasedLeft = true
        Mouse.releasedLeft = true
    elseif button == RIGHT then
        Mouse.justPressedRight = false
        Mouse.pressedRight = false
        Mouse.justReleasedRight = true
        Mouse.releasedRight = true
    elseif button == MIDDLE then
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
    Mouse.x, Mouse.y = push.toGame(x, y)
    Mouse.screenX, Mouse.screenY = x, y
    Mouse.isMoved = true
end

return Mouse
