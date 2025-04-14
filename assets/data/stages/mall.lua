local upperBopper
local bottomBopper
local santa

function preload()
	return {
	    {"image", SCRIPT_PATH .. "bgWalls"},
	    {"image", SCRIPT_PATH .. "upperBop"},
	    {"image", SCRIPT_PATH .. "bgEscalator"},
	    {"image", SCRIPT_PATH .. "christmasTree"},
	    {"image", SCRIPT_PATH .. "bottomBop"},
	    {"image", SCRIPT_PATH .. "fgSnow"},
	    {"image", SCRIPT_PATH .. "santa"}
	}
end

function create()
	self.camZoom = 0.8

	self.boyfriendPos = {x = 970, y = 100}
	self.boyfriendCam = {x = 0, y = -100}

	local bg = Sprite(-350, -396)
	bg:loadTexture(paths.getImage(SCRIPT_PATH .. 'bgWalls'))
	bg:setGraphicSize(math.floor(bg.width * 0.8))
	bg:updateHitbox()
	bg:setScrollFactor(0.2, 0.2)
	self:add(bg)

	upperBopper = Sprite(-240, -90)
	upperBopper:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'upperBop'))
	upperBopper:addAnimByPrefix('bop', 'Upper Crowd Bob', 24, false)
	upperBopper:play('bop')
	upperBopper:setGraphicSize(math.floor(upperBopper.width * 0.85))
	upperBopper:updateHitbox()
	upperBopper:setScrollFactor(0.3, 0.3)
	self:add(upperBopper)

	local bgEscalator = Sprite(-600, -128)
	bgEscalator:loadTexture(paths.getImage(SCRIPT_PATH .. 'bgEscalator'))
	bgEscalator:setGraphicSize(math.floor(bgEscalator.width * 0.9))
	bgEscalator:updateHitbox()
	bgEscalator:setScrollFactor(0.3, 0.3)
	self:add(bgEscalator)

	local tree = Sprite(370, -250)
	tree:loadTexture(paths.getImage(SCRIPT_PATH .. 'christmasTree'))
	tree:setScrollFactor(0.4, 0.4)
	self:add(tree)

	bottomBopper = Sprite(-300, 140)
	bottomBopper:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'bottomBop'))
	bottomBopper:addAnimByPrefix('bop', 'Bottom Level Boppers', 24, false)
	bottomBopper:play('bop')
	bottomBopper:setGraphicSize(math.floor(bottomBopper.width * 1))
	bottomBopper:updateHitbox()
	bottomBopper:setScrollFactor(0.9, 0.9)
	self:add(bottomBopper)

	local fgSnow = Sprite(-601, 700)
	fgSnow:loadTexture(paths.getImage(SCRIPT_PATH .. 'fgSnow'))
	local color = Color.fromHEX(0xF3F4F5)
	local fgSnowFill = Graphic(fgSnow.x, fgSnow.y + fgSnow.height, fgSnow.width, 500, color)
	self:add(fgSnow)
	self:add(fgSnowFill)

	santa = Sprite(-840, 150)
	santa:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'santa'))
	santa:addAnimByPrefix('idle', 'santa idle in fear', 24, false)
	santa:play('idle')
	self:add(santa)
end

function beat()
	upperBopper:play('bop', true)
	bottomBopper:play('bop', true)
	santa:play('idle', true)
end
