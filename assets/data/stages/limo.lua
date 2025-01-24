local BackgroundDancer = require "backgrounddancer"

local bgLimo
local grpLimoDancers
local limo
local fastCar
local fastCarCanDrive = true
local fastCarSpeed = 170

local shader = Shader("wave")
shader.intensity = 2.68
shader.speed = 6.22

shader.position = {0.484756097561, 0.351104341203}
shader.radius = 0.13532459616
local timeThreshold = math.rad(360 / 6.22)

local function resetFastCar()
	fastCarSpeed = love.math.random(170, 220)
	fastCar.x = -12600 - (fastCarSpeed * 32)
	fastCar.y = love.math.random(140, 250)
	fastCar.velocity.x = 0
	fastCarCanDrive = true
end

local function fastCarDrive()
	util.playSfx(paths.getSound('gameplay/carPass' .. love.math.random(0, 1)))

	fastCar.velocity.x = fastCarSpeed / game.dt
	fastCarCanDrive = false
	Timer.wait(2, function() resetFastCar() end)
end

function create()
	self.dadCam.y = 86
	self.camZoom = 0.9

	self.boyfriendPos = {x = 1078, y = -156}
	self.boyfriendCam = {x = -200, y = 0}

	local skyBG = Sprite(-150, -50)
	skyBG:loadTexture(paths.getImage(SCRIPT_PATH .. 'limoSunset'))
	skyBG:setScrollFactor(0.36, 0.11)
	self:add(skyBG)
	skyBG.shader = shader:get()

	bgLimo = Sprite(-200, 480)
	bgLimo:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'bgLimo'))
	bgLimo:addAnimByPrefix('drive', "background limo pink", 24)
	bgLimo:play('drive')
	bgLimo:setScrollFactor(0.4, 0.4)
	self:add(bgLimo)

	grpLimoDancers = Group()
	self:add(grpLimoDancers)

	for i = 0, 4 do
		local dancer = BackgroundDancer((370 * i) + 230, bgLimo.y - 380)
		dancer:setScrollFactor(0.4, 0.4)
		grpLimoDancers:add(dancer)
	end

	limo = Sprite(-120, 550)
	limo:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'limoDrive'))
	limo:addAnimByPrefix('drive', "Limo stage", 24)
	limo:play('drive')

	fastCar = Sprite(-300, 160)
	fastCar:loadTexture(paths.getImage(SCRIPT_PATH .. 'fastCarLol'))
	fastCar.moves = true
	self:add(fastCar, true)
	resetFastCar()

	local skyOverlay = Sprite(-428, -304)
	skyOverlay:loadTexture(paths.getImage(SCRIPT_PATH .. "limoOverlay"))
	skyOverlay.blend = "add"
	skyOverlay:setGraphicSize(skyOverlay.width * 0.76)
	skyOverlay:updateHitbox()
	skyOverlay.alpha = 0.168
	skyOverlay:setScrollFactor(0.23, 0.18)
	self:add(skyOverlay, true)
end

function postCreate()
	state:insert(state:indexOf(state.gf) + 1, limo)
end

local bgLimoTime = 0
local cameraOffset = {0, 0}
local offsetTime = 0
function update(dt)
	bgLimoTime = bgLimoTime + dt / 2
	bgLimo.x = -200 + 120 * math.sin(bgLimoTime)
	for i = 0, 4 do
		grpLimoDancers.members[i + 1].x = ((370 * i) + 230) + 120 * math.sin(bgLimoTime)
	end

	offsetTime = offsetTime + dt
	cameraOffset[1] = 14 * math.sin(offsetTime * 1.5)
	cameraOffset[2] = 14 * math.cos(offsetTime * 2.5)

	shader.__time = shader.__time % timeThreshold
end

function onCameraMove(event)
	event.offset.x, event.offset.y =
		event.offset.x + cameraOffset[1], event.offset.y + cameraOffset[2]
end

function beat()
	for _, spr in pairs(grpLimoDancers.members) do
		spr:dance()
	end
	if love.math.randomBool(10) and fastCarCanDrive then
		fastCarDrive()
	end
end