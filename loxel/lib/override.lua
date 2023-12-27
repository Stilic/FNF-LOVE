---@diagnostic disable: duplicate-set-field
-- LUA 5.2-LUA 5.3 and LUA 5.0 BELOW REIMPLEMENTATIONS
bit32, iter, utf8 = bit, ipairs(math), require "utf8"
local __string__, __number__, __table__ = "string", "number", "table"
local __integer__, __float__ = "integer", "float"

function string.split(self, sep, t)
	t = t or {}
	for s in self:gmatch((not sep or sep == '') and '(.)' or '([^' .. sep .. ']+)') do
		table.insert(t, s)
	end
	return t
end

function string.replace(self, pattern, rep) -- note: you could just do gsub instead of replace
	return self:gsub('%' .. pattern, rep)
end

function table.find(list, value)
	for i, v in next, list do if v == value then return i end end
end

function table.remove(list, callback)
	local idx, v = type(callback) == __number__ and callback or (callback == nil and #list) or nil
	local j = idx or 1

	for i = j, #list do
		if (idx == nil and callback(list, i, j) or i == idx) then
			v, list[i] = list[i]
		else
			if i ~= j then list[j], list[i] = list[i] end
			j = j + 1
		end
	end

	return v
end

function table.reverse(list)
	for i = 1, #list / 2, 1 do
		list[i], list[#list - i + 1] = list[#list - 1 + 1], list[i]
	end
end

function table.delete(list, object)
	local index = table.find(list, object)
	if index then
		table.remove(list, index)
		return true
	end
	return false
end

function table.clear(list)
	for i in next, list do list[i] = nil end
end

function math.type(v)
	return (v >= -2147483648 and v <= 2147483647 and math.floor(v) == v) and
		__integer__ or __float__
end

function math.clamp(x, min, max) return math.min(math.max(x, min or 0), max or 1) end

math.bound = function(...)
	love.markDeprecated(2, "math.bound", "function", "renamed", "math.clamp")
	return math.clamp(...)
end

function math.round(x) return x >= 0 and math.floor(x + .5) or math.ceil(x - .5) end

-- EXTRA FUNCTIONS
math.positive_infinity = math.huge
math.negative_infinity = -math.huge

math.noise = love.math.noise

function __NULL__() end

-- https://gist.github.com/FreeBirdLjj/6303864?permalink_comment_id=3400522#gistcomment-3400522
function switch(param, case_table)
	return (case_table[param] or case_table.default or __NULL__)()
end

local checktype_str = "bad argument #%d to '%s' (%s expected, got %s)"
function checktype(level, value, arg, functionName, expectedType)
	if type(value) ~= expectedType then
		error(checktype_str:format(arg, functionName, expectedType, type(value)), level + 1)
	end
end

function table.merge(a, b)
	for i, v in next, b do a[i] = v end
end

function table.keys(list, includeIndices, keys)
	keys = keys or {}
	for i in includeIndices and iter or next, list, includeIndices and 0 or nil do
		table.insert(keys, i)
	end
	return keys
end

function string.ext(self) return self:sub(1 - (self:reverse():find('%.') or 1)) end

function string.hasExt(self)
	return self:match("%.([^%.]+)$") ~= nil
end

function string.withoutExt(self)
	return self:sub(0, -1 - (self:reverse():find('%.') or 1))
end

function string.fileName(self, parts)
	local separator = package.config:sub(1, 1)
	parts = parts or {}
	for part in self:split(separator) do
		table.insert(parts, part)
	end
	return parts[#parts]
end

function string.startsWith(self, prefix) return self:find(prefix, 1, true) == 1 end

function string.endsWith(self, suffix)
	return self:find(suffix, 1, true) == #self - (#suffix - 1)
end

function string.contains(self, s) return self:find(s) and true or false end

function string.isSpace(self, pos)
	if (#self < 1 or pos < 1 or pos > #self) then return false end
	local c = self:byte(pos)
	return (c > 8 and c < 14) or c == 32
end

function string.ltrim(self)
	local i, r = #self, 1
	while (r <= i and self:isSpace(r)) do r = r + 1 end
	return self:sub(r)
end

function string.rtrim(self)
	local i = #self
	local r = i - 1
	while (r > 0 and self:isSpace(r)) do r = r - 1 end
	return self:sub(1, r)
end

function string.trim(self) return self:ltrim():rtrim() end

function table.splice(tbl, start, count, ...)
	local removedItems = {}
	if start < 0 then start = #tbl + start + 1 end
	count = count or 0
	for i = 1, count do
		if tbl[start] then
			table.insert(removedItems, tbl[start])
			table.remove(tbl, start)
		else
			break
		end
	end
	local args = {...}
	for i = #args, 1, -1 do table.insert(tbl, start, args[i]) end
	return removedItems
end

function table.clone(list, includeIndices, clone)
	clone = clone or {}
	for i, v in includeIndices and iter or next, list, includeIndices and 0 or nil do
		clone[i] = type(v) == __table__ and table.clone(v) or v
	end
	return clone
end

function math.odd(x) return x % 2 >= 1 end -- 1, 3, etc

function math.even(x) return x % 2 < 1 end -- 2, 4, etc

function math.lerp(a, b, t) return a + (b - a) * t end

function math.remapToRange(x, start1, stop1, start2, stop2)
	return start2 + (x - start1) * ((stop2 - start2) / (stop1 - start1))
end

-- please use math.floor/round instead if you want the precision to be 0
function math.truncate(x, precision, round)
	precision = 10 ^ (precision or 2)
	return (round and math.round or math.floor)(precision * x) / precision
end

math.roundDecimal = function(...)
	love.markDeprecated(2, "math.roundDecimal", "function", "renamed", "math.truncate")
	return math.clamp(...)
end

local intervals = {'B', 'KB', 'MB', 'GB', 'TB'}
function math.countbytes(x)
	local i = 1
	while x >= 0x400 and i < 5 do
		x = x / 0x400
		i = i + 1
	end
	return math.truncate(x, 2, true) .. " " .. intervals[i]
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