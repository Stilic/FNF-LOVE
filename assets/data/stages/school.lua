local BackgroundGirls = require "backgroundgirls"

local bgGirls
local floor = math.floor

function create()
	camZoom = 1

	game.camera:resize(floor(1280 / 6), floor(720 / 6), 1, 1, true)
	game.camera.pixelPerfect = true
	game.camera.antialiasing = false

	boyfriendPos = {x = 1080, y = 60}
	gfPos = {x = 580, y = 120}
	dadPos = {x = 20, y = -400}

	boyfriendCam = {x = 85, y = 100}
	dadCam = {x = -75, y = 150}

	local bgSky = Sprite()
	bgSky:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebSky'))
	bgSky:setScrollFactor(0.1, 0.1)
	add(bgSky)
	bgSky.antialiasing = false

	local bgSchool = Sprite(-12, 0)
	bgSchool:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebSchool'))
	bgSchool:setScrollFactor(0.6, 0.90)
	add(bgSchool)
	bgSchool.antialiasing = false

	local bgStreet = Sprite(0, -1)
	bgStreet:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebStreet'))
	add(bgStreet)
	bgStreet.antialiasing = false

	local fgTrees = Sprite(5, 0)
	fgTrees:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebTreesBack'))
	fgTrees:updateHitbox()
	add(fgTrees)
	fgTrees.antialiasing = false

	local bgTrees = Sprite(-100, -168)
	bgTrees:setFrames(paths.getPackerAtlas(SCRIPT_PATH .. 'weebTrees'))
	bgTrees:addAnim('treeLoop', {
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
	}, 12)
	bgTrees:play('treeLoop')
	bgTrees:setScrollFactor(0.85, 0.85)
	add(bgTrees)
	bgTrees.antialiasing = false

	local treeLeaves = Sprite(-20, 10)
	treeLeaves:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'petals'))
	treeLeaves:setScrollFactor(0.85, 0.85)
	treeLeaves:addAnimByPrefix('PETALS ALL', 'PETALS ALL', 24, true)
	treeLeaves:play('PETALS ALL')
	treeLeaves:updateHitbox()
	add(treeLeaves)
	treeLeaves.antialiasing = false

	bgGirls = BackgroundGirls(0, 26, paths.formatToSongPath(PlayState.SONG.song) == "roses")
	bgGirls:updateHitbox()
	bgGirls.antialiasing = false
	add(bgGirls)
end

function postCreate()
	for _, nf in ipairs(notefields) do
		if nf.character then
			local m = nf.character
			m.scale.x, m.scale.y = 1, 1
			m:updateHitbox()
			m.x, m.y = floor(m.x / 6), floor(m.y / 6)
			if m.cameraPosition then
				m.cameraPosition.x, m.cameraPosition.y =
					floor(m.cameraPosition.x / 6), floor(m.cameraPosition.y / 6)
			end
			if m.animOffsets then
				for _, n in pairs(m.animOffsets) do
					n.x, n.y = floor(n.x / 6), floor(n.y / 6)
				end
			end
		end
	end

	dad:dance()
	dad:finish()
	cameraMovement(getCameraPosition(camTarget))
	game.camera:follow(camFollow, nil)
end

function postUpdate()
	game.camera.zoom = math.truncate(game.camera.zoom, 3)
end

function beat(b) bgGirls:dance() end
