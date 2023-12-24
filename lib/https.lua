local OS = love.system.getOS()
if OS == "Windows" then
	return package.loadlib("lib/windows/https", "luaopen_https")
elseif OS == "Linux" then
	return package.loadlib("lib/linux/https", "luaopen_https")
elseif OS == "OS X" then
	return package.loadlib("lib/osx/https", "luaopen_https")
else
	local __NULL__ = function () end
	return setmetatable({}, {__index = function () return __NULL__ end})
end
