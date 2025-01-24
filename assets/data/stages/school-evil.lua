local canvas, canvasSprite
local shader = Shader("wiggle")

function create()
	self.camZoom = 1.05
	self.boyfriendPos = {x = 970, y = 320}
	self.gfPos = {x = 580, y = 430}
	self.boyfriendCam = {x = -100, y = -100}

	-- me and my weird workarounds...
	-- this is to keep it pixelated btw
	canvasSprite = paths.getImage(SCRIPT_PATH .. 'evilSchoolBG')
	canvas = love.graphics.newCanvas(311, 161)

	local bgStreet = Sprite(-200, 0, canvas)
	bgStreet:setScrollFactor(0.8, 1)
	bgStreet:setGraphicSize(bgStreet.width * 6)
	bgStreet:updateHitbox()
	self:add(bgStreet)
	bgStreet.antialiasing = false

	local floor = Sprite(-200, 0)
	floor:loadTexture(paths.getImage(SCRIPT_PATH .. 'evilSchoolFG'))
	floor:setGraphicSize(floor.width * 6)
	floor:updateHitbox()
	self:add(floor)
	floor.antialiasing = false
end

function postCreate()
	if state.dad then
		state:insert(state:indexOf(state.dad), Trail(state.dad, 4, 24, 0.3, 0.069))
	end
end

function postUpdate(dt)
	shader.__time = shader.__time % (2 * math.pi)
end

function draw()
	if not canvasSprite then return end
	canvas:renderTo(function()
		love.graphics.push("all")
		love.graphics.clear()
		canvasSprite:setFilter("nearest", "nearest")
		love.graphics.setShader(shader:get())
		love.graphics.draw(canvasSprite)
		love.graphics.pop()
	end)
end

function leave()
	canvas:release()
end