function create()
	self.camZoom = 0.9

	self.boyfriendPos = {x = 1100, y = 100}
	self.gfPos = {x = 480, y = 130}
	self.dadPos = {x = 300, y = 100}

	if PlayState.SONG.player2 == 'bf-pixel' then
		self.dadPos = {x = 300, y = 240}
		self.dadCam = {x = -200, y = -90}
	end

	local ground = ActorSprite(270, 460, 300, paths.getImage('menus/menuDesat'))
	ground:updateHitbox()
	ground.fov, ground.scale.x, ground.scale.y = 40, 2, 2
	ground.rotation.x = -90
	--[[local ground = ParallaxImage(270, 100, 1280, 720, paths.getImage('menus/menuDesat'))
	ground.offsetBack = {x = 200, y = -300}
	ground.offsetFront = {x = 0, y = -150}
	ground.scrollFactorBack = {x = 0.4, y = 0.4}
	ground.scrollFactorFront = {x = 1.2, y = 1.2}
	ground.scaleBack = 1.1
	ground.scaleFront = 1.8]]
	self:add(ground)
end

function postCreate()
	game.camera.bgColor = {0.5, 0.5, 0.5}
	self.camZoom = 0.75
end
