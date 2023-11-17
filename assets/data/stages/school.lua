local bgGirls

function create()
    self.camZoom = 1.05
    self.camSpeed = 1

    self.boyfriendPos = {x = 970, y = 320}
    self.gfPos = {x = 580, y = 430}
    self.dadPos = {x = 100, y = 100}

    self.boyfriendCam = {x = -100, y = -100}
    self.gfCam = {x = 0, y = 0}
    self.dadCam = {x = 0, y = 0}

    PlayState.pixelStage = true

    GameOverSubstate.characterName = 'bf-pixel-dead'
    GameOverSubstate.deathSoundName = 'gameplay/fnf_loss_sfx-pixel'
    GameOverSubstate.loopSoundName = 'gameOver-pixel'
    GameOverSubstate.endSoundName = 'gameOverend-pixel'

    if state.SONG.song:lower() == 'thorns' then
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
    else
        local bgSky = Sprite()
        bgSky:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebSky'))
        bgSky:setScrollFactor(0.1, 0.1)
        self:add(bgSky)
        bgSky.antialiasing = false

        local repositionShit = -200

        local bgSchool = Sprite(repositionShit, 0)
        bgSchool:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebSchool'))
        bgSchool:setScrollFactor(0.6, 0.90)
        self:add(bgSchool)
        bgSchool.antialiasing = false

        local bgStreet = Sprite(repositionShit, 0)
        bgStreet:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebStreet'))
        bgStreet:setScrollFactor(0.95, 0.95)
        self:add(bgStreet)
        bgStreet.antialiasing = false

        local widShit = math.floor(bgSky.width * 6)

        local fgTrees = Sprite(repositionShit + 170, 130)
        fgTrees:loadTexture(paths.getImage(SCRIPT_PATH .. 'weebTreesBack'))
        fgTrees:setGraphicSize(math.floor(widShit * 0.8))
        fgTrees:updateHitbox()
        self:add(fgTrees)
        fgTrees.antialiasing = false

        local bgTrees = Sprite(repositionShit - 380, -800)
        bgTrees:setFrames(paths.getPackerAtlas(SCRIPT_PATH .. 'weebTrees'))
        bgTrees:addAnim('treeLoop', {
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
        }, 12)
        bgTrees:play('treeLoop')
        bgTrees:setScrollFactor(0.85, 0.85)
        self:add(bgTrees)
        bgTrees.antialiasing = false

        local treeLeaves = Sprite(repositionShit, -40)
        treeLeaves:setFrames(paths.getSparrowAtlas(SCRIPT_PATH .. 'petals'))
        treeLeaves:setScrollFactor(0.85, 0.85)
        treeLeaves:addAnimByPrefix('PETALS ALL', 'PETALS ALL', 24, true)
        treeLeaves:play('PETALS ALL')
        treeLeaves:setGraphicSize(widShit)
        treeLeaves:updateHitbox()
        self:add(treeLeaves)
        treeLeaves.antialiasing = false

        bgSky:setGraphicSize(widShit)
        bgSchool:setGraphicSize(widShit)
        bgStreet:setGraphicSize(widShit)
        bgTrees:setGraphicSize(math.floor(widShit * 1.4))

        bgSky:updateHitbox()
        bgSchool:updateHitbox()
        bgStreet:updateHitbox()
        bgTrees:updateHitbox()

        bgGirls = BackgroundGirls(-100, 190, state.SONG.song:lower() == 'roses')
        bgGirls:setScrollFactor(0.9, 0.9)
        bgGirls:setGraphicSize(math.floor(bgGirls.width * 6))
        bgGirls:updateHitbox()
        bgGirls.antialiasing = false
        self:add(bgGirls)

        if PlayState.storyMode and state.SONG.song:lower() == 'roses' then
            game.sound.play(paths.getSound('gameplay/ANGRY_TEXT_BOX'))
        end
    end
end

function postCreate()
    tvShader = love.graphics.newShader[[
        extern number time;
        extern number bulgeFactor;
        extern number rgbSplit;
        extern number blurAmount;
        extern number lineDensity;
        extern number vignetteIntensity;

        vec4 blur(vec2 uv, Image texture) {
            vec4 sum = vec4(0.0);
            sum += Texel(texture, uv - 4.0 * blurAmount);
            sum += Texel(texture, uv - 3.0 * blurAmount);
            sum += Texel(texture, uv - 2.0 * blurAmount);
            sum += Texel(texture, uv - blurAmount);
            sum += Texel(texture, uv);
            sum += Texel(texture, uv + blurAmount);
            sum += Texel(texture, uv + 2.0 * blurAmount);
            sum += Texel(texture, uv + 3.0 * blurAmount);
            sum += Texel(texture, uv + 4.0 * blurAmount);
            return sum / 9.0;
        }

        vec4 addLines(vec2 uv) {
            number lines = sin((uv.y - time) * lineDensity) * 0.05 + 0.5;
            vec4 linesColor = vec4(lines, lines, lines, lines);
            return linesColor;
        }

        vec4 addVignette(vec2 uv) {
            number vignette = smoothstep(vignetteIntensity * 1.0, -1.0, length(uv - 0.5) * 2.0) + 3.0;
            vignette *= smoothstep(vignetteIntensity * 4.0, -1.0, length(uv - 0.5) * 2.0);
            vec4 vignetteColor = vec4(vignette, vignette, vignette, vignette);
            return vignetteColor;
        }

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 center = vec2(0.5, 0.5);
            vec2 offset = texture_coords - center;
            number distance = length(offset);
            vec2 bulgeCoords = center + offset * (1.0 + bulgeFactor * pow(distance, 2.0));
            vec4 bulgeColor = Texel(texture, bulgeCoords);

            vec2 rgbOffset = vec2(rgbSplit, 0.0);
            vec4 redChannel = Texel(texture, bulgeCoords - rgbOffset);
            vec4 blueChannel = Texel(texture, bulgeCoords + rgbOffset);

            vec4 finalColor = vec4(bulgeColor.r, bulgeColor.g, bulgeColor.b, bulgeColor.a);

            finalColor = blur(bulgeCoords, texture);
            finalColor *= addLines(bulgeCoords);
            finalColor *= addVignette(bulgeCoords);
            return finalColor * color;
        }
    ]]

    tvShader:send("bulgeFactor", 0.15)
    tvShader:send("rgbSplit", 0.002)
    tvShader:send("blurAmount", 0.0005)
    tvShader:send("lineDensity", 280)
    tvShader:send("vignetteIntensity", 0.5)

    game.camera.shader = tvShader
    state.camHUD.shader = tvShader
    state.camOther.shader = tvShader
end

local time = 0
function update(dt)
    time = time + dt
    tvShader:send("time", time*0.8)
end

function beat(b) if state.SONG.song:lower() ~= 'thorns' then bgGirls:dance() end end
