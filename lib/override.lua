-- LUA 5.2-LUA 5.3 REIMPLEMENTATIONS
function string.split(self, sep, t)
	t = t or {}
	for s in self:gmatch((not sep or sep == '') and '(.)' or '([^'..sep..']+)') do table.insert(t, s) end
	return t
end

function string.replace(self, pattern, rep) -- note: you could just do gsub instead of replace
	return self:gsub('%'..pattern, rep)
end

function table.find(table, value)
	for i, v in next, table do if v == value then return i end end
end

function table.clear(table, includeKeys)
	for i in includeKeys and next or iter, table, not includeKeys and 0 or nil do rawset(table, i, nil) end
end

function math.clamp(x, min, max) return math.max(min, math.min(x, max)) end

function math.round(x) return x >= 0 and math.floor(x + .5) or math.ceil(x - .5) end

bit32, iter = bit, ipairs(math)

-- EXTRA FUNCTIONS
function table.keys(table, includeIndices, keys)
	keys = keys or {}
	for i in includeIndices and iter or next, table, includeIndices and 0 or nil do table.insert(keys, i) end
	return keys
end

function string.ext(self) return self:sub(1 - (self:reverse():find('%.') or 1)) end

function string.withoutExt(self)
	return self:sub(0, -1 - (self:reverse():find('%.') or 1))
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

function math.odd(x) return x % 2 >= 1 end -- 1, 3, etc

function math.even(x) return x % 2 < 1 end -- 2, 4, etc

function math.lerp(x, y, i) return x + (y - x) * i end

function math.truncate(x, precision, round)
	round = round and math.round or math.floor
	if not precision or precision > 0 then
		precision = 10 ^ (precision or 2)
		return round(precision * x) / precision
	end
	return round(x)
end

function math.remap(x, start1, stop1, start2, stop2)
	return start2 + (x - start1) * ((stop2 - start2) / (stop1 - start1))
end

math.noise = require "lib.noise"
ffi = require "ffi"

pcall(function()
	ffi.cdef[[
		void Sleep(int ms);
		int poll(struct pollfd *fds, unsigned long nfds, int timeout);
	]]

	if ffi.os == "Windows" then
		function love.timer.sleep(s)
			ffi.C.Sleep(math.max(s*1000, 0))
		end
	else
		function love.timer.sleep(s)
			ffi.C.poll(nil, 0, math.max(s*1000, 0))
		end
	end
end)