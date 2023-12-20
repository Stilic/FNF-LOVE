-- TODO: make offsets works me think

---@diagnostic disable: duplicate-set-field
---@class Camera:Object
local Camera = Object:extend("Camera")

local canvas
local canvasTable = {nil, stencil = true}

Camera.__defaultCameras = {}

local _ogSetColor, _simpleCamera
local function setSimpleColor(v, ...)
	if type(v) == "table" then
		_ogSetColor(_simpleCamera:getMultColor(unpack(v)))
	else
		_ogSetColor(_simpleCamera:getMultColor(v, ...))
	end
end

function Camera.__init(canv)
	canvas = canv
	canvasTable[1] = canv
end

function Camera:new(x, y, width, height)
	Camera.super.new(self, x, y)

	self.simple = true
	self.isSimple = true -- indicates if its in simple render

	-- these will turn complex rendering mode
	self.clipCam = flags.LoxelDefaultClipCamera or false
	self.antialiasing = true

	self.width = width and (width > 0 and width) or game.width
	self.height = height and (height > 0 and height) or game.height

	self.scroll = {x = 0, y = 0}
	self.rotation = 0
	self.angle = 0
	self.target = nil
	self.zoom = 1

	self.bgColor = {0, 0, 0, 0}

	self.__zoom = {x = 1, y = 1}
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

function Camera:update(dt)
	local isnum = type(self.zoom) == "number"
	self.__zoom.x = isnum and self.zoom or self.zoom.x
	self.__zoom.y = isnum and self.zoom or self.zoom.y

	if self.target then
		self.scroll.x = self.target.x - self.width / 2
		self.scroll.y = self.target.y - self.height / 2
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
				self.__shakeX = self.__shakeX + shakeVal * self.__zoom.x
			end

			if self.__shakeAxes:find('y') then
				local shakeVal =
					love.math.random(-1, 1) * self.__shakeIntensity *
						self.height
				self.__shakeY = self.__shakeY + shakeVal * self.__zoom.y
			end
		end
	end
end

function Camera:canDraw()
	local isnum = type(self.zoom) == "number"
	self.__zoom.x = isnum and self.zoom or self.zoom.x
	self.__zoom.y = isnum and self.zoom or self.zoom.y

	return self.visible and self.exists and next(self.__renderQueue) and
		self.alpha > 0 and (self.scale.x * self.__zoom.x) ~= 0 and
		(self.scale.y * self.__zoom.y) ~= 0
end

function Camera:getMultColor(r, g, b, a)
	return self.color[1] * math.min(r, 1), self.color[2] * math.min(g, 1),
		self.color[3] * math.min(b, 1), self.alpha * (math.min(a or 1, 1))
end

function Camera:draw()
	if not self:canDraw() then return end
	local winWidth, winHeight = love.graphics.getDimensions()
	if not self.simple or self.shader or (self.antialiasing and
			(self.x ~= math.floor(self.x) or self.y ~= math.floor(self.y) or
			self.scale.x ~= 1 or self.scale.y ~= 1) or
			math.min(winWidth / game.width, winHeight / game.height) > 1) or
		self.alpha < 1 or self.rotation ~= 0 then
		self:drawComplex(true)
	else
		self:drawSimple(true)
	end
end

function Camera:drawSimple(_skipCheck)
	if not _skipCheck and not self:canDraw() then return end
	self.isSimple = true

	local r, g, b, a = love.graphics.getColor()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local xc, yc, wc, hc = love.graphics.getScissor()

	love.graphics.push()

	local w2, h2 = self.width / 2, self.height / 2
	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)

	love.graphics.translate((winWidth - scale * game.width) / 2,
							(winHeight - scale * game.height) / 2)
	if not flags.LoxelDisableScissorOnRenderCameraSimple then
		local x, y = (winWidth - (scale * self.scale.x) * game.width) / 2,
				 (winHeight - (scale * self.scale.y) * game.height) / 2

		if self.clipCam then
			x, y = self.x * scale + x, self.y * scale + y
		end
		love.graphics.setScissor(math.round(x), math.round(y),
								 math.round(self.width * scale * self.scale.x) - 1,
								 math.round(self.height * scale * self.scale.y) - 1)
	end

	love.graphics.setColor(self.bgColor[1], self.bgColor[2],
						   self.bgColor[3], self.bgColor[4])
	love.graphics.rectangle("fill", 0, 0, self.width, self.height)
	love.graphics.setColor(r, g, b, a)

	love.graphics.scale(scale)

	love.graphics.translate(w2 + self.__shakeX, h2 + self.__shakeY)
	love.graphics.scale(self.__zoom.x * self.scale.x, self.__zoom.y * self.scale.y)
	love.graphics.rotate(math.rad(self.angle + self.rotation))
	love.graphics.translate(-w2, -h2)

	love.graphics.setBlendMode("alpha", "alphamultiply")

	_ogSetColor = love.graphics.setColor
	love.graphics.setColor = setSimpleColor
	_simpleCamera = self

	for i, o in next, self.__renderQueue do
		if type(o) == "function" then
			o(self)
		else
			o:__render(self)
		end
		self.__renderQueue[i] = nil
	end

	love.graphics.setColor = _ogSetColor

	love.graphics.pop()

	if self.__flashAlpha > 0 then
		love.graphics.setColor(self.__flashColor[1], self.__flashColor[2],
							   self.__flashColor[3], self.__flashAlpha)
		love.graphics.rectangle("fill", (winWidth - scale * game.width) / 2,
										(winHeight - scale * game.height) / 2,
										self.width, self.height)
	end

	love.graphics.setScissor(xc, yc, wc, hc)
	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
end

function Camera:drawComplex(_skipCheck)
	if not _skipCheck and not self:canDraw() then return end
	self.isSimple = false

	local r, g, b, a = love.graphics.getColor()
	local shader = self.shader and love.graphics.getShader()
	local blendMode, alphaMode = love.graphics.getBlendMode()
	local lineStyle = love.graphics.getLineStyle()
	local lineWidth = love.graphics.getLineWidth()
	local min, mag, anisotropy = canvas:getFilter()

	local cv = love.graphics.getCanvas()

	love.graphics.setCanvas(canvasTable)
	love.graphics.clear(self.bgColor[1], self.bgColor[2],
						self.bgColor[3], self.bgColor[4])
	love.graphics.push()

	local w2, h2 = self.width / 2, self.height / 2
	if not self.clipCam then
		love.graphics.translate(w2 + self.x,
								h2 + self.y)
	else
		love.graphics.translate(w2 + self.__shakeX, h2 + self.__shakeY)
	end
	love.graphics.rotate(math.rad(self.angle))
	love.graphics.scale(self.__zoom.x, self.__zoom.y)
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

	love.graphics.pop()

	if self.__flashAlpha > 0 then
		love.graphics.setColor(self.__flashColor[1], self.__flashColor[2],
							   self.__flashColor[3], self.__flashAlpha)
		love.graphics.rectangle("fill", 0, 0, self.width, self.height)
	end

	love.graphics.setCanvas(cv)

	love.graphics.setShader(self.shader)
	love.graphics.setColor(self.color[1] * self.alpha,
						   self.color[2] * self.alpha,
						   self.color[3] * self.alpha,
						   self.alpha)
	love.graphics.setBlendMode("alpha", "premultiplied")

	mode = self.antialiasing and "linear" or "nearest"
	canvas:setFilter(mode, mode, anisotropy)

	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)

	if self.clipCam then
		love.graphics.draw(canvas,
						   (winWidth / 2) + (self.x * scale),
						   (winHeight / 2) + (self.y * scale),
						   math.rad(self.rotation),
						   scale * self.scale.x, scale * self.scale.y,
						   game.width / 2, game.height / 2)
	else
		love.graphics.draw(canvas, winWidth / 2, winHeight / 2,
						   math.rad(self.rotation),
						   scale * self.scale.x, scale * self.scale.y,
						   game.width / 2, game.height / 2)
	end

	canvas:setFilter(min, mag, anisotropy)
	love.graphics.setColor(r, g, b, a)
	love.graphics.setBlendMode(blendMode, alphaMode)
	love.graphics.setLineStyle(lineStyle)
	love.graphics.setLineWidth(lineWidth)
	if self.shader then love.graphics.setShader(shader) end
end

if flags.LoxelForceRenderCameraComplex then
	Camera.draw = Camera.drawComplex
elseif flags.LoxelDisableRenderCameraComplex then
	Camera.draw = Camera.drawSimple
end

return Camera
