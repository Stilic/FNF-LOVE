---@diagnostic disable: duplicate-set-field
-- LUA 5.2-LUA 5.3 and LUA 5.0 BELOW REIMPLEMENTATIONS
bit32, iter, utf8 = bit, ipairs(math), require "utf8"
local __string__, __number__, __table__ = "string", "number", "table"
local __integer__, __float__ = "integer", "float"

local split_t
local function gsplit(s) table.insert(split_t, s) end
function string:split(sep, t)
	split_t = t or {}
	self:gsub((sep and sep ~= "") and "([^" .. sep .. "]+)" or ".", gsplit)
	return split_t
end

function string:replace(pattern, rep) -- note: you could just do gsub instead of replace
	return self:gsub("%" .. pattern, rep)
end

local s -- see https://luajit.org/extensions.html
s, table.new = pcall(require, "table.new")
if not s then function table.new( --[[narray, nhash]]) return {} end end

s, table.clear = pcall(require, "table.clear")
if not s then function table.clear(t) for i in pairs(t) do t[i] = nil end end end

if not table.move then
	function table.move(a, f, e, t, b)
		b = b or a; for i = f, e do b[i + t - 1] = a[i] end
		return b
	end
end

function table.find(t, value)
	for i = 1, #t do if t[i] == value then return i end end
end

local ogremove = table.remove or function(t, pos)
	local n = #t; if pos == nil then pos = n end;
	local v = t[pos]; if pos < n then table.move(t, pos + 1, n, pos) end;
	t[n] = nil; return v
end
function table.remove(list, idx)
	if idx == nil or type(idx) == __number__ then return ogremove(list, idx) end

	local j, v = 1
	for i = j, #list do
		if list[i] and idx(list, i, j) then
			v, list[i] = list[i]
		else
			if i ~= j then list[j], list[i] = list[i] end
			j = j + 1
		end
	end
	return v
end

function table.reverse(list)
	local n = #list + 1
	for i = 1, (n - 1) / 2 do list[i], list[n - i] = list[n - i], list[i] end
end

function table.delete(list, object)
	local index = table.find(list, object)
	if index then
		table.remove(list, index)
		return true
	end
	return false
end

function math.type(v)
	return (v >= -2147483648 and v <= 2147483647 and math.floor(v) == v) and
		__integer__ or __float__
end

function math.clamp(x, min, max) return math.min(math.max(x, min or 0), max or 1) end

function math.round(x) return x >= 0 and math.floor(x + .5) or math.ceil(x - .5) end

-- EXTRA FUNCTIONS
math.positive_infinity, math.negative_infinity = math.huge, -math.huge
math.noise = love.math.perlinNoise or love.math.noise
math.simplex = love.math.simplexNoise or math.noise
math.perlin = math.noise

function __NULL__() end

-- https://gist.github.com/FreeBirdLjj/6303864?permalink_comment_id=3400522#gistcomment-3400522
function switch(param, case_table) return (case_table[param] or case_table.default or __NULL__)() end

function bind(self, callback) return function(...) callback(self, ...) end end

local checktype_str = "bad argument #%d to '%s' (%s expected, got %s)"

function checktype(level, value, arg, functionName, expectedType)
	if type(value) ~= expectedType then
		error(checktype_str:format(arg, functionName, expectedType, type(value)), level + 1)
	end
end

local regex_ext = "%.([^%.]+)$"
local regex_withoutExt = "(.+)%..+$"

function string:ext() return self:match(regex_ext) or self end

function string:hasExt() return self:match(regex_ext) ~= nil end

function string:withoutExt() return self:match(regex_withoutExt) or self end

function string:capitalize() return self:sub(1, 1):upper() .. self:sub(2) end

function string:fileName(parts)
	parts = self:split(package.config:sub(1, 1), parts)
	return parts[#parts]
end

function string:startsWith(prefix) return self:find(prefix, 1, true) == 1 end

function string:endsWith(suffix) return self:find(suffix, 1, true) == #self - #suffix + 1 end

function string:contains(s) return self:find(s) and true or false end

function string:isSpace(pos)
	pos = self:byte(pos); return pos and (pos > 8 and pos < 14 or pos == 32)
end

function string:ltrim()
	local i, r = #self, 1
	while r <= i and self:isSpace(r) do r = r + 1 end
	return self:sub(r)
end

function string:rtrim()
	local r = #self - 1
	while r > 0 and self:isSpace(r) do r = r - 1 end
	return self:sub(1, r)
end

function string:trim() return self:ltrim():rtrim() end

function table.merge(a, b) for i, v in pairs(b) do a[i] = v end end

function table.keys(list, includeIndices, keys)
	keys = keys or table.new(#list, 0)
	for i in (includeIndices and pairs or ipairs)(list) do table.insert(keys, i) end
	return keys
end

function table.clone(list, clone)
	clone = clone or table.new(#list, 0)
	for i, v in pairs(list) do clone[i] = type(v) == __table__ and table.clone(v) or v end
	return clone
end

function table.splice(list, start, count, ...)
	local removed, args, n = {}, {...}, #list
	if start < 0 then start = n + start + 1 end
	for i = 0, math.min(count or 0, n - start) do
		table.insert(removed, table.remove(list, start))
	end
	for i = #args, 1, -1 do table.insert(list, start, args[i]) end
	return removed
end

function math.odd(x) return x % 2 >= 1 end -- 1, 3, etc

function math.even(x) return x % 2 < 1 end -- 2, 4, etc

function math.wrap(x, a, b) return ((x - a) % (b - a)) + a end

function math.lerp(a, b, t) return a + (b - a) * t end

function math.remapToRange(x, start1, stop1, start2, stop2)
	return start2 + (x - start1) * ((stop2 - start2) / (stop1 - start1))
end

-- please use math.floor/round instead if you want the precision to be 0
function math.truncate(x, precision, round)
	precision = 10 ^ (precision or 2)
	; return (round and math.round or math.floor)(precision * x) / precision
end

local intervals, countbytesf = {"B", "KB", "MB", "GB" --[[, "TB"]]}, "%.2f %s"
function math.countbytes(x, i)
	i = i or 1
	while x >= 0x400 and i < 4 do
		x, i = x / 0x400, i + 1
	end
	return countbytesf:format(x, intervals[i])
end

-- LOVE2D EXTRA FUNCTIONS
function love.math.randomBool(chance)
	return love.math.random(0, 100) < (chance or 50)
end

-- Gets the current device
---@return string -- The current device. 'Desktop' or 'Mobile'
function love.system.getDevice()
	local os = love.system.getOS()
	if os == "Android" or os == "iOS" then
		return "Mobile"
	elseif os == "OS X" or os == "Windows" or os == "Linux" then
		return "Desktop"
	end
	return "Unknown"
end

if love.system.getDevice() == "Desktop" then
	function love.window.getMaxDesktopDimensions()
		local xmax, ymax = 0, 0
		for i = 1, love.window.getDisplayCount() do
			local x, y = love.window.getDesktopDimensions(i)
			if x > xmax then xmax = x end
			if y > ymax then ymax = y end
		end
		return xmax, ymax
	end
else
	love.window.getMaxDesktopDimensions = love.window.getDesktopDimensions
end

if --[[not love.markDeprecated actually this is better and]] debug then
	-- this is stupid
	local __markDeprecated__, __Sl__, __none__ = "markDeprecated", "Sl", ""
	local __functionvariant__, __functionvariantin__ = "functionvariant", "function variant in"
	local __methodvariant__, __methodvariantin__ = "methodvariant", "method variant in"
	local __replaced__, __replcaedby__ = "replcaed", "(replaced by %s)"
	local __renamed__, __renamedto__ = "renamed", "(renamed to %s)"
	local __warning__ = "LOVE - Warning: %s:%d: Using deprecated %s %s %s"
	local deprecated = {}
	local ignore = {
		["love.graphics.stencil"] = true,
		["love.graphics.setStencilTest"] = true
	}
	function love.markDeprecated(level, name, apiname, deprecationtname, replacement)
		checktype(2, level, 1, __markDeprecated__, __number__)
		checktype(2, name, 2, __markDeprecated__, __string__)
		if ignore[name] then return end

		checktype(2, apiname, 3, __markDeprecated__, __string__)
		checktype(2, deprecationtname, 4, __markDeprecated__, __string__)

		local info = debug.getinfo(level + 1, __Sl__)
		if not deprecated[name] then deprecated[name] = {} end
		if deprecated[name][info.source .. info.currentline] then return end

		deprecated[name][info.source .. info.currentline] = true
		local what
		if apiname == __functionvariant__ then
			what = __functionvariantin__
		elseif apiname == __methodvariant__ then
			what = __methodvariantin__
		else
			what = apiname
		end

		local isreplaced, extra = deprecationtname == __replaced__
		if isreplaced or deprecationtname == __renamed__ then
			checktype(2, replacement, 5, __markDeprecated__, __string__)
			extra = (isreplaced and __replacedby__ or __renamedto__):format(replacement)
		end

		print(__warning__:format(info.source:sub(2), info.currentline, what, name, extra or __none__))
	end
end
