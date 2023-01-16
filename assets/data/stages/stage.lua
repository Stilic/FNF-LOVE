function create()
    self.camZoom = 0.9

    local bg = Sprite(-600, -200):load(
                   paths.getImage(SCRIPT_PATH .. "stageback"))
    bg.antialiasing = true
    bg:setScrollFactor(0.9)
    self:add(bg)

    local stageFront = Sprite(-650, 600):load(
                           paths.getImage(SCRIPT_PATH .. "stagefront"))
    stageFront:setGraphicSize(math.floor(stageFront.width * 1.1))
    stageFront:updateHitbox()
    stageFront.antialiasing = true
    stageFront:setScrollFactor(0.9)
    self:add(stageFront)

    local stageCurtains = Sprite(-500, -300):load(
                              paths.getImage(SCRIPT_PATH .. "stagecurtains"))
    stageCurtains:setGraphicSize(math.floor(stageCurtains.width * 0.9))
    stageCurtains:updateHitbox()
    stageCurtains.antialiasing = true
    stageCurtains:setScrollFactor(1.3)
    self:add(stageCurtains)
end

local anims, add = {l = {-1, 0}, r = {1, 0}, u = {0, -1}, d = {0, 1}}, 25

function postUpdate()
    local mustHit = state:getCurrentMustHit()
    if mustHit ~= nil and not mustHit then
        char = state.dad
    else
        char = state.boyfriend
    end
    local idx
    if char.curAnim and #char.curAnim.name > 4 then idx = string.sub(char.curAnim.name, 5, 5) end
    if idx ~= nil then
        idx = string.lower(idx)
        local anim = anims[idx]
        state.camFollow.x, state.camFollow.y =
            state.camFollow.x + add * anim[1], state.camFollow.y + add * anim[2]
    end
end
