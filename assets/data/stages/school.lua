function create()
    self.camZoom = 1.05
    self.camSpeed = 1

    self.boyfriendPos = {x = 970, y = 320}
    self.gfPos = {x = 580, y = 430}
    self.dadPos = {x = 100, y = 100}

    self.boyfriendCam = {x = -100, y = -100}
    self.gfCam = {x = 0, y = 0}
    self.dadCam = {x = 0, y = 0}

    local bgSky = Sprite()
    bgSky:load(paths.getImage(SCRIPT_PATH .. 'weebSky'))
    bgSky:setScrollFactor(0.1, 0.1)
    self:add(bgSky)
    bgSky.antialiasing = false

    local repositionShit = -200

    local bgSchool = Sprite(repositionShit, 0)
    bgSchool:load(paths.getImage(SCRIPT_PATH .. 'weebSchool'))
    bgSchool:setScrollFactor(0.6, 0.90)
    self:add(bgSchool)
    bgSchool.antialiasing = false

    local bgStreet = Sprite(repositionShit, 0)
    bgStreet:load(paths.getImage(SCRIPT_PATH .. 'weebStreet'))
    bgStreet:setScrollFactor(0.95, 0.95)
    self:add(bgStreet)
    bgStreet.antialiasing = false

    local widShit = math.floor(bgSky.width * 6)
    -- if not ClientPrefs.data.lowQuality then
        local fgTrees = Sprite(repositionShit + 170, 130)
        fgTrees:load(paths.getImage(SCRIPT_PATH .. 'weebTreesBack'))
        fgTrees:setGraphicSize(math.floor(widShit * 0.8))
        fgTrees:updateHitbox()
        self:add(fgTrees)
        fgTrees.antialiasing = false
    -- end

    local bgTrees = Sprite(repositionShit - 380, -800)
    bgTrees:setFrames(paths.getPackerAtlas(SCRIPT_PATH .. 'weebTrees'))
    bgTrees:addAnim('treeLoop', {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18}, 12)
    bgTrees:play('treeLoop')
    bgTrees:setScrollFactor(0.85, 0.85)
    self:add(bgTrees)
    bgTrees.antialiasing = false

    -- if not ClientPrefs.data.lowQuality then
        local treeLeaves = Sprite(repositionShit, -40)
        treeLeaves:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'petals'))
        treeLeaves:setScrollFactor(0.85, 0.85)
        treeLeaves:addAnimByPrefix('PETALS ALL', 'PETALS ALL', 24, true)
        treeLeaves:play('PETALS ALL')
        treeLeaves:setGraphicSize(widShit)
        treeLeaves:updateHitbox()
        self:add(treeLeaves)
        treeLeaves.antialiasing = false
    -- end

    bgSky:setGraphicSize(widShit)
    bgSchool:setGraphicSize(widShit)
    bgStreet:setGraphicSize(widShit)
    bgTrees:setGraphicSize(math.floor(widShit * 1.4))

    bgSky:updateHitbox()
    bgSchool:updateHitbox()
    bgStreet:updateHitbox()
    bgTrees:updateHitbox()

    -- if not ClientPrefs.data.lowQuality then
        bgGirls = BackgroundGirls(-100, 190)
        bgGirls:setScrollFactor(0.9, 0.9)

        bgGirls:setGraphicSize(math.floor(bgGirls.width * 6))
        bgGirls:updateHitbox()
        bgGirls.antialiasing = false
        self:add(bgGirls)
    -- end

    switch(paths.formatToSongPath(state.song.song), {
        ['roses']=function()
            bgGirls:swapDanceType()
            --paths.playSound('gameplay/ANGRY_TEXT_BOX')
        end
    })
end

function countdownTick(swagCounter)
    bgGirls:dance()
end

function beatHit()
    bgGirls:dance()
end

function destroy()
    close()
end