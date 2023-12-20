local ffi = require "ffi"
local dwmapi = ffi.load("dwmapi")

local Util = {}
ffi.cdef[[
	typedef void* HWND;
    typedef unsigned int DWORD;
    typedef int BOOL;
    typedef const void* LPCVOID;
    typedef int HRESULT;
    typedef const char* LPCSTR;
    
    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName);
    HWND FindWindowExA(HWND hwndParent, HWND hwndChildAfter, LPCSTR lpszClass, LPCSTR lpszWindow);
    HWND GetActiveWindow(void);
    
    HRESULT DwmSetWindowAttribute(HWND hwnd, DWORD dwAttribute, LPCVOID pvAttribute, DWORD cbAttribute);
]]

local function getWindowHandle(title)
    local window = ffi.C.FindWindowA(nil, ffi.string(title))
    if window == nil then
        window = ffi.C.FindWindowExA(ffi.C.GetActiveWindow(), nil, nil, ffi.string(title))
    end
    return window
end

function Util.setDarkMode(title, enable)
    if enable == nil then enable = false end

	local window = getWindowHandle(title)
    if window ~= nil then
		local darkMode = ffi.new("int[1]", (enable and 1 or 0))
        local result = dwmapi.DwmSetWindowAttribute(window, 19, darkMode, ffi.sizeof(darkMode))
        if result ~= 0 then
            dwmapi.DwmSetWindowAttribute(window, 20, darkMode, ffi.sizeof(darkMode))
        end
    end
end

return Util