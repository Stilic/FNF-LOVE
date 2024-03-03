local Keyboard = {
	---@class Keys
	keys = {
		ANY = nil,
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
	},

	---@class justPressed:Keys
	justPressed = {},

	---@class pressed:Keys
	pressed = {},

	---@class justReleased:Keys
	justReleased = {},

	---@class released:Keys
	released = {},

	---@type string
	input = nil
}

for key in pairs(Keyboard.keys) do Keyboard.released[key] = true end

function Keyboard.reset()
	for key in pairs(Keyboard.keys) do
		if Keyboard.justPressed[key] then Keyboard.justPressed[key] = nil end
		if Keyboard.justReleased[key] then
			Keyboard.justReleased[key] = nil
		end
	end
	Keyboard.input = nil
end

local invalidKeys = {
	'escape', 'shift', 'windows', 'alt', 'ctrl', 'pageup', 'pagedown',
	'home', 'end', 'insert', 'delete', 'backspace', 'capslock', 'scrolllock',
	'numlock', 'return', 'left', 'down', 'up', 'right', 'tab', 'menu',
	'printscreen', 'pause', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8',
	'f9', 'f10', 'f11', 'f12'
}
local shiftKeys = {
	["0"] = ")",
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	[";"] = ":",
	["'"] = '"',
	["`"] = "~",
	[","] = "<",
	["."] = ">",
	["/"] = "?",
	["\""] = "|"
}

function Keyboard.onPressed(key)
	for k, value in pairs(Keyboard.keys) do
		if key == 'kpenter' then key = "return" end
		if key == 'lshift' or key == 'rshift' then key = 'shift' end
		if key == 'lgui' or key == 'rgui' then key = 'windows' end
		if key == 'lalt' or key == 'ralt' then key = 'alt' end
		if key == 'lctrl' or key == 'rctrl' then key = 'ctrl' end

		if value == key then
			Keyboard.justPressed[k] = true
			Keyboard.pressed[k] = true
			Keyboard.justReleased[k] = nil
			Keyboard.released[k] = nil
		end
	end
	Keyboard.justPressed.ANY = true
	Keyboard.pressed.ANY = true
	Keyboard.justReleased.ANY = nil
	Keyboard.released.ANY = nil

	if not table.find(invalidKeys, key) then
		if key == 'space' then key = ' ' end
		if key:startsWith('kp') then key = key:gsub('kp', '') end
		if Keyboard.pressed.SHIFT and shiftKeys[key] then
			key = shiftKeys[key]
		end
		Keyboard.input = key
	end
end

function Keyboard.onReleased(key)
	for k, value in pairs(Keyboard.keys) do
		if key == 'lshift' or key == 'rshift' then key = 'shift' end
		if key == 'lgui' or key == 'rgui' then key = 'windows' end
		if key == 'lalt' or key == 'ralt' then key = 'alt' end
		if key == 'lctrl' or key == 'rctrl' then key = 'ctrl' end

		if value == key then
			Keyboard.justPressed[k] = nil
			Keyboard.pressed[k] = nil
			Keyboard.justReleased[k] = true
			Keyboard.released[k] = true
		end
	end
	Keyboard.justPressed.ANY = nil
	Keyboard.pressed.ANY = nil
	Keyboard.justReleased.ANY = true
	Keyboard.released.ANY = true
end

return Keyboard
