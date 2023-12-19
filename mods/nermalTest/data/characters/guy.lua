local flipped = true
local flippedIdle = false
local defaultY = 0
function postCreate()
    defaultY = self.y
end
function beat()
    if state.health < 1.8 then
        flipped = not flipped
        state.iconP2.flipX = flipped
    end

    if PlayState.conductor.currentBeat % 1 == 0 and self.curAnim.name == 'idle' then
        flippedIdle = not flippedIdle
        self.flipX = flippedIdle
        self.y = self.y + 20
        Timer.tween(0.15, self, {y = self.y - 20}, 'out-cubic')
    end
end

function step()
    if state.health > 1.8 and PlayState.conductor.currentStep % 2 == 0 then
        flipped = not flipped
        state.iconP2.flipX = flipped
    end
end

function update(e)
	local angleOfs = math.random(-5, 5)
	if state.health > 1.8 then
		state.iconP2.angle = angleOfs
	else
		state.iconP2.angle = 0
	end
    if self.curAnim and self.curAnim.name ~= 'idle' then
        Timer.cancelTweensOf(self)
        self.y = defaultY
        self.flipX = false
    end
end