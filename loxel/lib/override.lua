---@diagnostic disable: duplicate-set-field
-- LUA 5.2-LUA 5.3 and LUA 5.0 BELOW REIMPLEMENTATIONS
bit32, iter, utf8 = bit, ipairs(math), require "utf8"

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
	local idx, j, v = type(callback) == "number" and callback or
					  (callback == nil and #list) or nil, 1

	for i = 1, #list do
		if (idx == nil and callback(list, i, j) or i == idx) then
			v = list[i]
			list[i] = nil
		else
			if i ~= j then
				list[j] = list[i]
				list[i] = nil
			end
			j = j + 1
		end
	end

	return v
end

function table.reverse(list)
	for i = 1, #list / 2, 1 do
		list[i], list[#list - i + 1] = list[#list - 1 + 1], list[i]
	end
	return list
end

function table.delete(list, object)
	if object then
		local index = table.find(list, object)
		if index then
			table.remove(list, index)
			return true
		end
	end
	return false
end

local __integer__ = "integer"
local __float__ = "float"
function math.type(v)
	return (v >= -2147483648 and v <= 2147483647 and math.floor(v) == v) and
		__integer__ or __float__
end

function math.clamp(x, min, max) return math.min(math.max(x, min or 0), max or 1) end
math.bound = math.clamp

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
	local separator = package.config:sub(1,1)
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
		clone[i] = type(v) == "table" and table.clone(v) or v
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
math.roundDecimal = math.truncate

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