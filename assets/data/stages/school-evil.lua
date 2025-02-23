local shader = Shader("wiggle")

local floor = math.floor

function create()
	camZoom = 1

	boyfriendPos = {x = 1080, y = 53}
	gfPos = {x = 580, y = 120}
	dadPos = {x = 0, y = -240}

	boyfriendCam = {x = 85, y = 95}
	dadCam = {x = -75, y = 138}

	game.camera:resize(floor(1280 / 6), floor(720 / 6), 1, 1, true)
	game.camera.pixelPerfect = true
	game.camera.antialiasing = false

	local bg = Sprite(-24, 0, paths.getImage(SCRIPT_PATH .. 'evilSchoolBG'))
	bg:setScrollFactor(0.6, 1)
	bg:updateHitbox()
	bg.antialiasing = false
	bg.shader = shader:get()
	add(bg)

	local floor = Sprite(0, 0)
	floor:loadTexture(paths.getImage(SCRIPT_PATH .. 'evilSchoolFG'))
	floor:updateHitbox()
	floor.antialiasing = false
	floor.shader = shader:get()
	add(floor)
end

function postCreate()
	if dad then
		state:insert(state:indexOf(dad), Trail(dad, 4, 24, 0.3, 0.069))
	end

	for _, nf in ipairs(notefields) do
		if nf.character then
			local m = nf.character
			m:setGraphicSize(m.width / 6)
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

function postUpdate(dt)
	shader.__time = shader.__time % (2 * math.pi)
	game.camera.zoom = math.truncate(game.camera.zoom, 3)
end
