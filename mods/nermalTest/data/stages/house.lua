function create()
    self.camZoom = 0.7

    self.gfPos = {x = 400, y = 50}

    local bg = Sprite(-600, -600):loadTexture(paths.getImage('bgstuffs/house'))
    bg.scale = {x = 1.6, y = 1.6}
    self:add(bg)
end

function postCreate() state.gf:setScrollFactor(1, 1) end