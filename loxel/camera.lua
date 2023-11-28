---@class Camera:Object
local Camera = Object:extend("Camera")

local canvas
local canvasTable = {nil, stencil = true}

Camera.__defaultCameras = {}

function Camera.__init(canv)
	canvas = canv
	canvasTable[1] = canv
end

function Camera:new(x, y, width, height)
	Camera.super.new(self, x, y)

	self.simple = true

	self.width = width and (width > 0 and width) or game.width
	self.height = height and (height > 0 and height) or game.height

	self.scroll = {x = 0, y = 0}
	self.target = nil
	self.alpha = 1
	self.angle = 0
	self.zoom = 1
	
	self.bgColor = {0, 0, 0, 0}

	self.__renderQueue = {}

	self.__flashColor = {1, 1, 1}
	self.__flashAlpha = 0
	self.__flashDuration = 0
	self.__flashComplete = nil

	self.__shakeX = 0
	self.__shakeY = 0
	self.__shakeAxes = 'xy'
	self.__shakeIntensity = 0
	self.__shakeDuration = 0
	self.__shakeComplete = nil
end

function Camera:update(dt)
	if self.target then
		self.scroll.x, self.scroll.y = self.target.x - self.width * 0.5,
									   self.target.y - self.height * 0.5
	end

	if self.__flashAlpha > 0 then
		self.__flashAlpha = self.__flashAlpha - dt / self.__flashDuration
		if self.__flashAlpha <= 0 and self.__flashComplete ~= nil then
			self.__flashComplete()
		end
	end

	self.__shakeX, self.__shakeY = 0, 0
	if self.__shakeDuration > 0 then
		self.__shakeDuration = self.__shakeDuration - dt
		if self.__shakeDuration <= 0 then
			if self.__shakeComplete ~= nil then
				self.__shakeComplete()
			end
		else
			if self.__shakeAxes:find('x') then
				local shakeVal =
					love.math.random(-1, 1) * self.__shakeIntensity * self.width
				self.__shakeX = self.__shakeX + shakeVal * self.zoom
			end

			if self.__shakeAxes:find('y') then
				local shakeVal =
					love.math.random(-1, 1) * self.__shakeIntensity *
						self.height
				self.__shakeY = self.__shakeY + shakeVal * self.zoom
			end
		end
	end
end

function Camera:shake(intensity, duration, onComplete, force, axes)
	if not force and (self.__shakeDuration > 0) then return end

	self.__shakeAxes = axes or 'xy'
	self.__shakeIntensity = intensity
	self.__shakeDuration = duration or 1
	self.__shakeComplete = onComplete or nil
end

function Camera:flash(color, duration, onComplete, force)
	if not force and (self.__flashAlpha > 0) then return end

	self.__flashColor = color or {1, 1, 1}
	duration = duration or 1
	if duration <= 0 then duration = 0.000001 end
	self.__flashDuration = duration
	self.__flashComplete = onComplete or nil
	self.__flashAlpha = 1
end

function Camera:draw()
	if self.alpha <= 0 then return end
	if self.shader or self.alpha < 1 or not self.simple then
		self:drawComplex()
	else
		self:drawSimple()
	end
end

function Camera:drawSimple()
	local r, g, b, a = love.graphics.getColor()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local xc, yc, wc, hc = love.graphics.getScissor()

	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)
	local x, y = (winWidth - scale * game.width) / 2,
				 (winHeight - scale * game.height) / 2
	love.graphics.translate(x, y)
	love.graphics.setScissor(x, y, game.width * scale, game.height * scale)
	love.graphics.scale(scale)

	local w2, h2 = self.width * 0.5, self.height * 0.5
	love.graphics.translate(w2 - self.x + self.__shakeX,
							h2 - self.y + self.__shakeY)
	love.graphics.rotate(math.rad(-self.angle))
	love.graphics.scale(self.zoom)
	love.graphics.translate(-w2, -h2)

	love.graphics.setBlendMode("alpha", "alphamultiply")

	for i, o in next, self.__renderQueue do
		if type(o) == "function" then
			o(self)
		else
			o:__render(self)
		end
		self.__renderQueue[i] = nil
	end

	if self.__flashAlpha > 0 then
		love.graphics.setColor(self.__flashColor[1], self.__flashColor[2],
							   self.__flashColor[3], self.__flashAlpha)
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
	end

	love.graphics.setScissor(xc, yc, wc, hc)

	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
end

function Camera:drawComplex()
	local r, g, b, a = love.graphics.getColor()
	local shader = self.shader and love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local lineStyle = love.graphics.getLineStyle()
	local lineWidth = love.graphics.getLineWidth()

	local cv = love.graphics.getCanvas()

	love.graphics.setCanvas(canvasTable)
	love.graphics.clear(self.bgColor[1], self.bgColor[2],
						self.bgColor[3], self.bgColor[4])
	love.graphics.push()

	local w2, h2 = self.width * 0.5, self.height * 0.5
	love.graphics.translate(w2 - self.x + self.__shakeX,
							h2 - self.y + self.__shakeY)
	love.graphics.rotate(math.rad(-self.angle))
	love.graphics.scale(self.zoom)
	love.graphics.translate(-w2, -h2)

	love.graphics.setBlendMode("alpha", "alphamultiply")

	for i, o in next, self.__renderQueue do
		if type(o) == "function" then
			o(self)
		else
			o:__render(self)
		end
		self.__renderQueue[i] = nil
	end

	if self.__flashAlpha > 0 then
		love.graphics.setColor(self.__flashColor[1], self.__flashColor[2],
							   self.__flashColor[3], self.__flashAlpha)
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
	end

	love.graphics.pop()
	love.graphics.setCanvas(cv)

	love.graphics.setShader(self.shader)
	love.graphics.setColor(self.alpha, self.alpha, self.alpha, self.alpha)
	love.graphics.setBlendMode("alpha", "premultiplied")

	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width,
						   winHeight / game.height)
	love.graphics.draw(canvas, (winWidth - scale * game.width) / 2,
					   (winHeight - scale * game.height) / 2, 0, scale)

	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
	love.graphics.setLineStyle(lineStyle)
	love.graphics.setLineWidth(lineWidth)
	if self.shader then love.graphics.setShader(shader) end
end

return Camera
