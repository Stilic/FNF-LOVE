-- LUA 5.2-LUA 5.3 REIMPLEMENTATIONS
function string.split(self, sep)
	if sep == "" then return {self:match((self:gsub(".", "(.)")))} end
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(self, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function string.replace(self, pattern, rep)
	local s = string.gsub(self, "%" .. pattern, rep)
	return s
end

function table.find(table,v)
	for i,v2 in next,table do
		if v2 == v then
			return i
		end
	end
end

function table.clear(t, includeKeys)
	if (includeKeys) then
		for i,_ in pairs(t) do rawset(t, i, nil) end
		return
	end
	while #t ~= 0 do rawset(t, #t, nil) end
end

function math.clamp(x,min,max)return math.max(min,math.min(x,max))end
function math.round(x)return x >= 0 and math.floor(x + .5) or math.ceil(x - .5)end

bit32 = bit

-- EXTRA FUNCTIONS
function table.keys(t, keys, includeI)
	if (type(keys) == "boolean") then
		local v = includeI
		includeI = keys; keys = v
	end
	keys = type(keys) == "table" and keys or {}
	for i in pairs(t) do
		if (type(i) ~= "number" or includeI) then table.insert(keys, i) end
	end
	return keys
end

function string.duplicate(s, i)
	local str = ""
	for i = 1, i do str = str .. s end
	return str
end
string.dupe = string.duplicate

function string.ext(self) return self:sub(1 - (self:reverse():find("%.") or 1))end
function string.withoutExt(self) return self:sub(0, -1-(self:reverse():find("%.") or 1))end

function string.startsWith(self, prefix) return self:find(prefix, 1, true) == 1 end
function string.endsWith(self, suffix) return self:find(suffix, 1, true) == #self - (#suffix - 1) end

function string.contains(self, s) return self:find(s) and true or false end

function string.isSpace(self, pos)
	if (#self < 1 or pos < 1 or pos > #self) then
		return false
	end
	local c = self:byte(pos)
	return (c > 8 and c < 14) or c == 32
end

function string.ltrim(self)
	local i = #self
	local r = 1
	while (r <= i and self:isSpace(r)) do
		r = r + 1
	end
	return r > 1 and self:sub(r, i) or self
end

function string.rtrim(self)
	local i = #self
	local r = 1
	while (r <= i and self:isSpace(i - r + 1)) do
		r = r + 1
	end
	return r > 1 and self:sub(0, i - r + 1) or self
end

function string.trim(self) return string.ltrim(self:rtrim()) end

function math.odd(self) return math.fmod(self, 2) == 0 end -- 2, 4, etc
function math.even(self) return not math.even(self) end -- 1, 3, etc

function math.lerp(from,to,i) return from+(to-from)*i end

function math.truncate(x, precision, round)
	if (precision == 0) then return math.floor(x) end
	
	precision = type(precision) == "number" and precision or 2
	
	x = x * math.pow(10, precision);
	return (round and math.floor(x + .5) or math.floor(x)) / math.pow(10, precision)
end

function math.remap(value, start1, stop1, start2, stop2)
	return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1))
end

math.noise = require "lib.noise"