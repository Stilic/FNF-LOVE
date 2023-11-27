--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--

---@class Classic
---@operator call:fun(...:any)
local Classic = {__class = "Classic"}
Classic.__index = Classic

---base function that can be called with Classic() or Classic:new()
function Classic:new() end

---returns the class with the tables functions and variables
---@return Classic
function Classic:extend(type)
    local cls = {}

    for k, v in pairs(self) do 
        if k:find("__") == 1 then cls[k] = v end 
    end

    cls.__class = type or "Unknown"
    cls.__index = cls
    cls.super = self
    setmetatable(cls, self)

    return cls
end

---implements functions to the class??? 
---@param ... unknown
function Classic:implement(...)
    for _, cls in pairs({...}) do
        for k, v in pairs(cls) do
            if self[k] == nil and type(v) == "function" then
                self[k] = v
            end
        end
    end
end

---no clue
---@param T any
function Classic:is(T)
    local mt = getmetatable(self)
    while mt do
        if mt == T then return true end
        mt = getmetatable(mt)
    end
    return false
end

function Classic:__tostring()
    return self.__class
end

---calls the new function with args
---@param ... any
---@return any
function Classic:__call(...)
    local obj = setmetatable({}, self)
    obj:new(...)
    return obj
end

return Classic
