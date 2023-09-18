-- LUA 5.2-LUA 5.3 REIMPLEMENTATIONS
function string.split(self, sep, t)
    t = t or {}
    for s in self:gmatch((not sep or sep == '') and '(.)' or '([^' .. sep ..
                             ']+)') do table.insert(t, s) end
    return t
end

function string.replace(self, pattern, rep) -- note: you could just do gsub instead of replace
    return self:gsub('%' .. pattern, rep)
end

function table.find(table, value)
    for i, v in next, table do if v == value then return i end end
end

function table.delete(self, object)
    if object then
        local index = table.find(self, object)
        if index then
            table.remove(self, index)
            return true
        end
    end
    return false
end

function math.clamp(x, min, max) return math.max(min, math.min(x, max)) end

function math.round(x) return x >= 0 and math.floor(x + .5) or math.ceil(x - .5) end

function math.bound(value, min, max) return math.max(min, math.min(max, value)) end

bit32, iter = bit, ipairs(math)

-- EXTRA FUNCTIONS
_G.switch = function(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

function table.keys(table, includeIndices, keys)
    keys = keys or {}
    for i in includeIndices and iter or next, table, includeIndices and 0 or nil do
        table.insert(keys, i)
    end
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

function math.odd(x) return x % 2 >= 1 end -- 1, 3, etc

function math.roundDecimal(number, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

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

function math.remapToRange(x, start1, stop1, start2, stop2)
    return start2 + (x - start1) * ((stop2 - start2) / (stop1 - start1))
end

local intervals = {'B', 'KB', 'MB', 'GB', 'TB'}
function math.countbytes(x)
    local i = 1
    while x >= 0x400 and i < 5 do
        x = x / 0x400;
        i = i + 1
    end
    return math.truncate(x, 2, true) .. " " .. intervals[i]
end

math.positive_infinity = math.huge
math.negative_infinity = -math.huge

math.noise = require "lib.noise"
