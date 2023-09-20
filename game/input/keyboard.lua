local Keyboard = Object:extend()

Keyboard.keys = {
    __index = Keyboard.keys,

    A = "a",
    B = "b",
    C = "c",
    D = "d",
    E = "e",
    F = "f",
    G = "g",
    H = "h",
    I = "i",
    J = "j",
    K = "k",
    L = "l",
    M = "m",
    N = "n",
    O = "o",
    P = "p",
    Q = "q",
    R = "r",
    S = "s",
    T = "t",
    U = "u",
    V = "v",
    W = "w",
    X = "x",
    Y = "y",
    Z = "z",
    ZERO = "0",
    ONE = "1",
    TWO = "2",
    THREE = "3",
    FOUR = "4",
    FIVE = "5",
    SIX = "6",
    SEVEN = "7",
    EIGHT = "8",
    NINE = "9",
    PAGEUP = "pageup",
    PAGEDOWN = "pagedown",
    HOME = "home",
    END = "end",
    INSERT = "insert",
    ESCAPE = "escape",
    MINUS = "-",
    PLUS = "+",
    DELETE = "delete",
    BACKSPACE = "backspace",
    LBRACKET = "[",
    RBRACKET = "]",
    BACKSLASH = "\\",
    CAPSLOCK = "capslock",
    SCROLL_LOCK = "scrolllock",
    NUMLOCK = "numlock",
    SEMICOLON = ";",
    QUOTE = "\'",
    ENTER = "return",
    SHIFT = "shift",
    COMMA = ",",
    PERIOD = ".",
    SLASH = "/",
    GRAVEACCENT = "`",
    CONTROL = "ctrl",
    ALT = "alt",
    SPACE = "space",
    UP = "up",
    DOWN = "down",
    LEFT = "left",
    RIGHT = "right",
    TAB = "tab",
    WINDOWS = "windows",
    MENU = "menu",
    PRINTSCREEN = "printscreen",
    BREAK = "pause",
    F1 = "f1",
    F2 = "f2",
    F3 = "f3",
    F4 = "f4",
    F5 = "f5",
    F6 = "f6",
    F7 = "f7",
    F8 = "f8",
    F9 = "f9",
    F10 = "f10",
    F11 = "f11",
    F12 = "f12",
    NUMPADZERO = "kp0",
    NUMPADONE = "kp1",
    NUMPADTWO = "kp2",
    NUMPADTHREE = "kp3",
    NUMPADFOUR = "kp4",
    NUMPADFIVE = "kp5",
    NUMPADSIX = "kp6",
    NUMPADSEVEN = "kp7",
    NUMPADEIGHT = "kp8",
    NUMPADNINE = "kp9",
    NUMPADMINUS = "kp-",
    NUMPADPLUS = "kp+",
    NUMPADPERIOD = "kp.",
    NUMPADMULTIPLY = "kp*",
    NUMPADSLASH = "kp/"
}

Keyboard.justPressed = setmetatable({}, Keyboard.keys)
Keyboard.pressed = setmetatable({}, Keyboard.keys)
Keyboard.justReleased = setmetatable({}, Keyboard.keys)
Keyboard.released = setmetatable({}, Keyboard.keys)

function Keyboard:init()
    for keys, value in pairs(Keyboard.keys) do
        Keyboard.justReleased[keys] = nil
        Keyboard.justPressed[keys] = nil
        Keyboard.pressed[keys] = nil
        Keyboard.released[keys] = value
    end
end

function Keyboard.onPressed(key)
    for keys, value in pairs(Keyboard.keys) do
        if key == 'lshift' or key == 'rshift' then key = 'shift' end
        if key == 'lgui' or key == 'rgui' then key = 'windows' end
        if key == 'lalt' or key == 'ralt' then key = 'alt' end
        if key == 'lctrl' or key == 'rctrl' then key = 'ctrl' end

        if value == key then
            Keyboard.justReleased[keys] = nil
            Keyboard.released[keys] = nil
            Keyboard.justPressed[keys] = value
            Keyboard.pressed[keys] = value
        end
    end
end

function Keyboard.onReleased(key)
    for keys, value in pairs(Keyboard.keys) do
        if key == 'lshift' or key == 'rshift' then key = 'shift' end
        if key == 'lgui' or key == 'rgui' then key = 'windows' end
        if key == 'lalt' or key == 'ralt' then key = 'alt' end
        if key == 'lctrl' or key == 'rctrl' then key = 'ctrl' end

        if value == key then
            Keyboard.justPressed[keys] = nil
            Keyboard.pressed[keys] = nil
            Keyboard.justReleased[keys] = value
            Keyboard.released[keys] = value
        end
    end
end

function Keyboard:update()
    for keys, value in pairs(Keyboard.keys) do
        if Keyboard.justPressed[keys] == value then rawset(Keyboard.justPressed, keys, nil) end
        if Keyboard.justReleased[keys] == value then rawset(Keyboard.justReleased, keys, nil) end
    end
end

return Keyboard