local s = {}

function s.create()
    local bg = Sprite(-600, -200):load(paths.getImage(path .. "stageback"))
    bg.antialiasing = true
    bg:setScrollFactor(0.9)
    self:add(bg)

    local stageFront = Sprite(-650, 600):load(
                           paths.getImage(path .. "stagefront"))
    stageFront:setGraphicSize(math.floor(stageFront.width * 1.1))
    stageFront:updateHitbox()
    stageFront.antialiasing = true
    stageFront:setScrollFactor(0.9)
    self:add(stageFront)

    local stageCurtains = Sprite(-500, -300):load(
                              paths.getImage(path .. "stagecurtains"))
    stageCurtains:setGraphicSize(math.floor(stageCurtains.width * 0.9))
    stageCurtains:updateHitbox()
    stageCurtains.antialiasing = true
    stageCurtains:setScrollFactor(1.3)
    self:add(stageCurtains)
end

return s
