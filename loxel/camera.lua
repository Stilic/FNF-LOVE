-- TODO: make offsets works me think

---@diagnostic disable: duplicate-set-field
---@class Camera:Object
local Camera = Object:extend("Camera")

local canvas
local stencilSupport = false
local canvasTable = {nil, stencil = true}

Camera.__defaultCameras = {}

function Camera.__init(canv)
	canvas = canv
	canvasTable[1] = canv

	if love.graphics.getTextureFormats then
		stencilSupport = love.graphics.getTextureFormats({canvas = true})["stencil8"]
	else
		local cv = love.graphics.getCanvas()
		stencilSupport = pcall(love.graphics.setCanvas, canvasTable)
		pcall(love.graphics.setCanvas, cv)
	end

	if not stencilSupport then Camera.draw = Camera.drawSimple end
end

function Camera:new(x, y, width, height)
	Camera.super.new(self, x, y)

	self.simple = true
	self.isSimple = true -- indicates if its in simple render

	-- these will turn complex rendering mode in some cases
	self.clipCam = flags.LoxelDefaultClipCamera == nil and true or flags.LoxelDefaultClipCamera
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

	self.__fadeColor = {1, 1, 1}
	self.__fadeAlpha = 0
	self.__fadeDuration = 0
	self.__fadeComplete = nil
	self.__fadeIn = false

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

function Camera:fade(color, duration, fadeIn, onComplete, force)
	if not force and (self.__fadeDuration > 0) then return end

	self.__fadeColor = color or {0, 0, 0}
	duration = duration or 1
	if duration <= 0 then duration = 0.000001 end
	self.__fadeDuration = duration
	self.__fadeComplete = onComplete or nil
	self.__fadeAlpha = fadeIn == true and 0.999999 or 0.000001
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

	if self.__fadeDuration > 0 then
		if self.__fadeIn then
			self.__fadeAlpha = self.__fadeAlpha - dt / self.__fadeDuration
			if self.__fadeAlpha <= 0 and self.__fadeComplete ~= nil then
				self.__fadeAlpha = 0
				self.__fadeComplete()
				self.__fadeDuration = 0
			end
		else
			self.__fadeAlpha = self.__fadeAlpha + dt / self.__fadeDuration
			if self.__fadeAlpha >= 1 and self.__fadeComplete ~= nil then
				self.__fadeAlpha = 1
				self.__fadeComplete()
				self.__fadeDuration = 0
			end
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

-- Simple Render
local _simpleCamera, _ogSetColor
local function setSimpleColor(r, g, b, a)
	if type(r) == "table" then
		_ogSetColor(_simpleCamera:getMultColor(r[1], r[2], r[3], r[4]))
	else
		_ogSetColor(_simpleCamera:getMultColor(r, g, b, a))
	end
end

function Camera:renderObjects()
	for i, o in ipairs(self.__renderQueue) do
		if type(o) == "function" then o(self)
		else
			o:__render(self)
			table.clear(o.__cameraQueue)
		end
		self.__renderQueue[i] = nil
	end
end

function Camera:drawSimple(_skipCheck)
	if not _skipCheck and not self:canDraw() then return end
	self.isSimple = true

	local grap = love.graphics
	local r, g, b, a = grap.getColor()
	local blendMode, alphaMode = grap.getBlendMode()
	local xc, yc, wc, hc = grap.getScissor()

	local x, y, w, h = self.x, self.y, self.width, self.height
	local sx, sy = self.scale.x, self.scale.y
	local w2, h2 = w / 2, h / 2

	_simpleCamera = self
	_ogSetColor, grap.setColor = grap.setColor, setSimpleColor

	game.__pushBoundScissor(w, h, sx, sy)
	if not flags.LoxelDisableScissorOnRenderCameraSimple then
		if self.clipCam then grap.setScissor(x, y, w, h)
		else grap.setScissor(0, 0, w, h) end
	end

	grap.push()

	local color = self.bgColor
	if color ~= nil and (not color[4] or color[4] > 0) then
		setSimpleColor(color)
		grap.rectangle("fill", 0, 0, w, h)
		setSimpleColor(r, g, b, a)
	end

	grap.translate(w2 + x + self.__shakeX, h2 + y + self.__shakeY)
	grap.scale(self.__zoom.x * sx, self.__zoom.y * sy)
	grap.rotate(math.rad(self.angle + self.rotation))
	grap.translate(-w2, -h2)

	grap.setBlendMode("alpha", "alphamultiply")
	self:renderObjects()

	game.__popBoundScissor()
	grap.pop()

	color = self.__flashColor
	if self.__flashAlpha > 0 then
		setSimpleColor(color[1], color[2], color[3], self.__flashAlpha)
		grap.rectangle("fill", 0, 0, w, h)
	end

	color = self.__fadeColor
	if self.__fadeDuration > 0 then
		setSimpleColor(color[1], color[2], color[3], self.__fadeAlpha)
		grap.rectangle("fill", 0, 0, w, h)
	end

	grap.setColor = _ogSetColor
	grap.setScissor(xc, yc, wc, hc)
	grap.setColor(r, g, b, a)
	grap.setBlendMode(blendMode, alphaMode)
end

function Camera:drawComplex(_skipCheck)
	if not _skipCheck and not self:canDraw() then return end
	self.isSimple = false

	local grap = love.graphics
	local r, g, b, a = grap.getColor()
	local shader = grap.getShader()
	local blendMode, alphaMode = grap.getBlendMode()
	local cv = grap.getCanvas()
	local min, mag, anisotropy = canvas:getFilter()
	local mode = self.antialiasing and "linear" or "nearest"
	canvas:setFilter(mode, mode, anisotropy)

	local x, y, w, h = self.x, self.y, self.width, self.height
	local sx, sy = self.scale.x, self.scale.y
	local w2, h2 = w / 2, h / 2
	local color = self.bgColor

	grap.setCanvas(canvasTable)
	grap.clear(color[1], color[2], color[3], color[4])
	grap.push(); grap.origin(); game.__literalBoundScissor(w, h, 1, 1)

	if self.clipCam then grap.translate(w2 + self.__shakeX, h2 + self.__shakeY)
	else grap.translate(w2 + x + self.__shakeX, h2 + y + self.__shakeY) end
	grap.rotate(math.rad(self.angle))
	grap.scale(self.__zoom.x, self.__zoom.y)
	grap.translate(-w2, -h2)

	grap.setBlendMode("alpha", "alphamultiply")
	self:renderObjects()

	color = self.__flashColor
	if self.__flashAlpha > 0 then
		if self.clipCam then grap.translate(w2 + self.__shakeX, h2 + self.__shakeY)
		else grap.translate(w2 + x + self.__shakeX, h2 + y + self.__shakeY) end
		grap.scale(1 / self.__zoom.x, 1 / self.__zoom.y)
		grap.translate(-w2, -h2)
		grap.setColor(color[1], color[2], color[3], self.__flashAlpha)
		grap.rectangle("fill", 0, 0, w, h)
	end

	color = self.__fadeColor
	if self.__fadeDuration > 0 then
		if self.clipCam then grap.translate(w2 + self.__shakeX, h2 + self.__shakeY)
		else grap.translate(w2 + x + self.__shakeX, h2 + y + self.__shakeY) end
		grap.scale(1 / self.__zoom.x, 1 / self.__zoom.y)
		grap.translate(-w2, -h2)
		grap.setColor(color[1], color[2], color[3], self.__fadeAlpha)
		grap.rectangle("fill", 0, 0, w, h)
	end

	game.__popBoundScissor()
	grap.pop()

	grap.setCanvas(cv)

	local alpha = self.alpha; color = self.color
	grap.setShader(self.shader)
	grap.setBlendMode("alpha", "premultiplied")
	grap.setColor(color[1] * alpha, color[2] * alpha, color[3] * alpha, alpha)

	if self.clipCam then
		grap.draw(canvas, w2 + x, h2 + y, math.rad(self.rotation), sx, sy, w2, h2)
	else
		grap.draw(canvas, w2, h2, math.rad(self.rotation), sx, sy, w2, h2)
	end

	canvas:setFilter(min, mag, anisotropy)
	grap.setColor(r, g, b, a)
	grap.setBlendMode(blendMode, alphaMode)
	if self.shader then grap.setShader(shader) end
end

if flags.LoxelForceRenderCameraComplex then
	Camera.draw = Camera.drawComplex
elseif flags.LoxelDisableRenderCameraComplex then
	Camera.draw = Camera.drawSimple
end

return Camera
