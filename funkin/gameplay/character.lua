local Character = Sprite:extend()

Character.editorMode = false

function Character:new(x, y, char, isPlayer)
    Character.super.new(self, x, y)

    if not Character.editorMode then
        self.script = Script("characters/" .. char)
        self.script.variables["self"] = self

        self.script:call("create")
    end

    self.char = char
    self.isPlayer = isPlayer or false
    self.animOffsets = {}

    self.__reverseDraw = false

    self.holdTime = 4
    self.lastHit = 0

    self.danceSpeed = 2
    self.danced = false

    local jsonData = paths.getJSON("data/characters/" .. self.char)
    if jsonData == nil then jsonData = paths.getJSON("data/characters/bf") end

    self:setFrames(paths.getAtlas(jsonData.image))

    self.imageFile = jsonData.image
    self.jsonScale = 1
    if jsonData.scale ~= 1 then
        self.jsonScale = jsonData.scale
        self:setGraphicSize(math.floor(self.width * self.jsonScale))
        self:updateHitbox()
    end

    if jsonData.sing_duration ~= nil then
        self.holdTime = jsonData.sing_duration
    end

    self.positionTable = {
        x = jsonData.position[1],
        y = jsonData.position[2]
    }
    self.cameraPosition = {
        x = jsonData.camera_position[1],
        y = jsonData.camera_position[2]
    }

    self.icon = jsonData.healthicon

    self.flipX = (jsonData.flip_x == true)
    self.jsonFlipX = self.flipX

    self.noAntialiasing = (jsonData.no_antialiasing == true)
    self.antialiasing = ClientPrefs.data.antialiasing and not self.noAntialiasing or
                                                          false

    self.animationsTable = jsonData.animations
    if self.animationsTable and #self.animationsTable > 0 then
        for _, anim in ipairs(self.animationsTable) do
            local animAnim = '' .. anim.anim
            local animName = '' .. anim.name
            local animFps = anim.fps
            local animLoop = anim.loop
            local animOffsets = anim.offsets
            local animIndices = anim.indices
            if animIndices ~= nil and #animIndices > 0 then
                self:addAnimByIndices(animAnim, animName, animIndices, animFps, animLoop)
            else
                self:addAnimByPrefix(animAnim, animName, animFps, animLoop)
            end

            if animOffsets ~= nil and #animOffsets > 1 then
                self:addOffset(animAnim, animOffsets[1], animOffsets[2])
            end
        end
    end

    if self.isPlayer ~= self.flipX then
        self.__reverseDraw = true
        self:switchAnim("singLEFT", "singRIGHT")
        self:switchAnim("singLEFTmiss", "singRIGHTmiss")
        self:switchAnim("singLEFT-loop", "singRIGHT-loop")
    end
    if self.isPlayer then self.flipX = not self.flipX end

    if self.__animations['danceLeft'] and self.__animations['danceRight'] then
        self.danceSpeed = 1
    end

    self.x = self.x + self.positionTable.x
    self.y = self.y + self.positionTable.y

    self:dance()
    self:finish()

    if not Character.editorMode then self.script:call("postCreate") end
end

function Character:switchAnim(oldAnim, newAnim)
    local leftAnim = self.__animations[oldAnim]
    if leftAnim and self.__animations[newAnim] then
        leftAnim.name = newAnim
        self.__animations[oldAnim] = self.__animations[newAnim]
        self.__animations[oldAnim].name = oldAnim
        self.__animations[newAnim] = leftAnim
    end

    local leftOffsets = self.animOffsets[oldAnim]
    if leftOffsets and self.animOffsets[newAnim] then
        self.animOffsets[oldAnim] = self.animOffsets[newAnim]
        self.animOffsets[newAnim] = leftOffsets
    end
end

function Character:update(dt)
    if self.curAnim then
        if self.animFinished and self.__animations[self.curAnim.name .. '-loop'] ~=
            nil then self:playAnim(self.curAnim.name .. '-loop') end
    end
    if not Character.editorMode then self.script:call("update", dt) end
    Character.super.update(self, dt)
    if not Character.editorMode then self.script:call("postUpdate", dt) end
end

function Character:draw()
    if not Character.editorMode then self.script:call("draw") end
    Character.super.draw(self)
    if not Character.editorMode then self.script:call("postDraw") end
end

function Character:__render(camera)
    if self.__reverseDraw then self.offset.x = self.offset.x * -1 end
    Character.super.__render(self, camera)
    if self.__reverseDraw then self.offset.x = self.offset.x * -1 end
end

function Character:step(s)
    if not Character.editorMode then self.script:call("step", s) end
    if not Character.editorMode then self.script:call("postStep", s) end
end

function Character:beat(b)
    if not Character.editorMode then self.script:call("beat", b) end
    if self.lastHit > 0 then
        if self.lastHit + PlayState.inst.stepCrochet * self.holdTime <
            PlayState.inst.time then
            self:dance()
            self.lastHit = 0
        end
    elseif b % self.danceSpeed == 0 then
        self:dance(self.danceSpeed < 2)
    end
    if not Character.editorMode then self.script:call("postBeat", b) end
end

function Character:playAnim(anim, force, frame)
    Character.super.play(self, anim, force, frame)

    local offset = self.animOffsets[anim]
    if offset then
        self.offset.x, self.offset.y = offset.x, offset.y
    else
        self.offset.x, self.offset.y = 0, 0
    end
end

function Character:sing(dir, miss)
    local anim = "sing" .. string.upper(Note.directions[dir + 1])
    if miss then anim = anim .. "miss" end
    self:playAnim(anim, true)

    self.lastHit = PlayState.inst.time
end

function Character:dance(force)
    if self.__animations and (not Character.editorMode and self.script:callReturn("dance")
                              or true) then
        if self.__animations["danceLeft"] and self.__animations["danceRight"] then
            self.danced = not self.danced

            if self.danced then
                self:playAnim("danceRight", force)
            else
                self:playAnim("danceLeft", force)
            end
        elseif self.__animations["idle"] then
            self:playAnim("idle", force)
        end
    end
end

function Character:addOffset(anim, x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    self.animOffsets[anim] = {x = x, y = y}
end

return Character
