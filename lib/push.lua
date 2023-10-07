--[[
push.lua v1.0

The MIT License (MIT)

Copyright (c) 2018 Ulysse Ramage

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

-- Modified by ViKaoy for FNF-LOVE
local settings

local pushWidth, pushHeight
local windowWidth, windowHeight
local scale = {x = 0, y = 0}
local offset = {x = 0, y = 0}

local function initValues()
	scale.x = windowWidth / pushWidth
	scale.y = windowHeight / pushHeight
end

local function toGame(x, y)
	local normalX, normalY

	x, y = x - offset.x, y - offset.y
	normalX, normalY = x / (pushWidth * scale.x), y / (pushHeight * scale.y)

	x = math.floor(normalX * pushWidth)
	y = math.floor(normalY * pushHeight)

	return x, y
end

local function toReal(x, y)
	local realX = offset.x + (pushWidth * x) / (pushWidth * scale.x)
	local realY = offset.y + (pushHeight * y) / (pushHeight * scale.y)

	return realX, realY
end

local function start()
	love.graphics.push()
	-- love.graphics.translate(offset.x, offset.y)
	-- love.graphics.scale(scale.x, scale.y)
end

local function finish()
	love.graphics.pop()
end

return {
	setupScreen = function(width, height, settingsTable)
		pushWidth, pushHeight = width, height
		windowWidth, windowHeight = love.graphics.getDimensions()
		settings = settingsTable
		initValues()
	end,

	setScissor = function(x, y, w, h)
		if x == nil and y == nil and w == nil and h == nil then
			-- love.graphics.setScissor()
		else
			-- love.graphics.setScissor(x, y, w, h)
		end
	end,

	toGame = toGame,
	toReal = toReal,
	start = start,
	finish = finish,

	resize = function(width, height)
		windowWidth, windowHeight = width, height
		initValues()
	end,

	getWidth = function() return pushWidth end,
	getHeight = function() return pushHeight end,
	getDimensions = function() return pushWidth, pushHeight end
}
