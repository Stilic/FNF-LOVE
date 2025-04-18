-- TODO: 
-- 1. Add rain shader
-- 2. Fix character positions
-- 3. FIX LIGHTNINGDAD IDLE BECAUSE IT'S REALLY REALLY BROKEN
local lightningStrikeBeat = 0
local lightningStrikeOffset = 8

local function doLightningStrike(playSound, beat)
    if playSound then util.playSfx(paths.getSound('gameplay/thunder_' .. love.math.random(1, 2))) end
    bgLight.alpha = 1
    stairsLight.alpha = 1
    state.boyfriend.alpha = 0
    state.dad.alpha = 0
    if state.gf then state.gf.alpha = 0 end
    Timer(state.timer):start(0.06, function()
        bgLight.alpha = 0
        stairsLight.alpha = 0
        state.boyfriend.alpha = 1
        state.dad.alpha = 1
        if state.gf then
            state.gf.alpha = 1
        end
    end)
    Timer(state.timer):start(0.12, function()
        bgLight.alpha = 1
        stairsLight.alpha = 1
        state.boyfriend.alpha = 0
        state.dad.alpha = 0
        if state.gf then
            state.gf.alpha = 0
        end
        state.tween:tween(bgLight, {alpha = 0}, 1.5)
        state.tween:tween(stairsLight, {alpha = 0}, 1.5)
        state.tween:tween(state.boyfriend, {alpha = 1}, 1.5)
        state.tween:tween(state.dad, {alpha = 1}, 1.5)
        if state.gf then
            state.tween:tween(state.gf, {alpha = 1}, 1.5)
        end
    end)
    lightningStrikeBeat = beat
    lightningStrikeOffset = love.math.random(8, 24)
    if state.boyfriend then
        state.boyfriend:play('scared', true)
    end
    if state.gf then
        state.gf:play('scared', true)
    end
end

function postCreate()
    lightningBf = Character(state.boyfriend.x, state.boyfriend.y, 'bf', true)
    lightningBf:setScrollFactor(state.boyfriend.scrollFactor.x, state.boyfriend.scrollFactor.y)
    lightningDad = Character(state.dad.x, state.dad.y, 'spooky')
    lightningDad:setScrollFactor(state.dad.scrollFactor.x, state.dad.scrollFactor.y)
    if state.gf then
        lightningGf = Character(state.gf.x, state.gf.y, 'gf')
        lightningGf:setScrollFactor(state.gf.scrollFactor.x, state.gf.scrollFactor.y)
    end
    bgLight.alpha = 0
    stairsLight.alpha = 0

    if state.gf then self:add(lightningGf) end
    self:add(lightningBf)
    self:add(lightningDad)

    if state.gf then state:insert(state:indexOf(state.gf), lightningGf) end
    state:insert(state:indexOf(state.boyfriend) , lightningBf)
    state:insert(state:indexOf(state.dad), lightningDad)
end

function postUpdate(dt)
    if lightningBf.curAnim.name ~= state.boyfriend.curAnim.name then
        lightningBf:playAnim(state.boyfriend.curAnim.name, true)
    else
        lightningBf.curFrame = state.boyfriend.curFrame
    end
    if lightningDad.curAnim.name ~= state.dad.curAnim.name then
        lightningDad:playAnim(state.dad.curAnim.name, true)
    else
        lightningDad.curFrame = state.dad.curFrame
    end
    if state.gf then
        if lightningGf.curAnim.name ~= state.gf.curAnim.name then
            lightningGf:playAnim(state.gf.curAnim.name, true)
        else
            lightningGf.curFrame = state.gf.curFrame
        end
    end
end

function beat(beat)
    if (beat == 4) and state.SONG.song == 'Spookeez Erect' then
        doLightningStrike(false, beat)
    end

    if (love.math.random(1, 10) == 1) and (beat > (lightningStrikeBeat + lightningStrikeOffset)) then
        doLightningStrike(true, beat)
    end
end