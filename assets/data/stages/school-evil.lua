local Sprite = loxel.Sprite
local Trail = loxel.effects.Trail

function create()
	self.camZoom = 1.05

	self.boyfriendPos = {x = 970, y = 320}
	self.gfPos = {x = 580, y = 430}

	self.boyfriendCam = {x = -100, y = -100}

	self.ratingPos = {x = -180, y = 260}

	GameOverSubstate.characterName = 'bf-pixel-dead'
	GameOverSubstate.deathSoundName = 'gameplay/fnf_loss_sfx-pixel'
	GameOverSubstate.loopSoundName = 'gameOver-pixel'
	GameOverSubstate.endSoundName = 'gameOverend-pixel'

	local posX = 400
	local posY = 200

	local bg = Sprite(posX, posY)
	bg:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'animatedEvilSchool'))
	bg:setScrollFactor(0.8, 0.9)
	bg.scale = {x = 6, y = 6}
	bg:addAnimByPrefix('background 2', 'background 2', 24, true)
	bg:play('background 2')
	bg.antialiasing = false
	self:add(bg)
end

function postCreate()
	local trailFx = Trail(state.dad, 4, 24, 0.3, 0.069)
	state:insert(state:indexOf(state.dad), trailFx)
end
