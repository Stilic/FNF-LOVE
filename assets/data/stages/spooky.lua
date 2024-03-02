local Sprite = loxel.Sprite

local hallowBG

function create()
	self.ratingPos = {x = -160, y = 240}

	hallowBG = Sprite(-200, -100)
	hallowBG:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'halloween_bg'))
	hallowBG:addAnimByPrefix('idle', 'halloweem bg0')
	hallowBG:addAnimByPrefix('lightning', 'halloweem bg lightning strike', 24,
		false)
	hallowBG:play('idle')
	self:add(hallowBG)
end

local lightningStrikeBeat = 0
local lightningOffset = love.math.random(8, 24)
function beat()
	if love.math.randomBool(10) and curBeat > lightningStrikeBeat +
		lightningOffset then
		game.sound.play(paths.getSound('gameplay/thunder_' ..
			love.math.random(1, 2)))
		hallowBG:play('lightning')

		game.camera:shake(0.001, 1.4)
		state.camHUD:shake(0.001, 1.4)

		lightningStrikeBeat = curBeat
		lightningOffset = love.math.random(8, 24)

		state.boyfriend:playAnim('scared', true)
		state.gf:playAnim('scared', true)

		state.boyfriend.lastHit = PlayState.conductor.time
		state.gf.lastHit = PlayState.conductor.time
	end
end
