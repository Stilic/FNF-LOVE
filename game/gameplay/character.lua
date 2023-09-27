local Character = Sprite:extend()

function Character:new(x, y, char, isPlayer)
    Character.super.new(self, x, y)

    self.char = char
    self.isPlayer = isPlayer or false
    self.animOffsets = {}

    self.__reverseDraw = false

    self.singDuration = 4
    self.lastHit = 0
    self.lastSing = nil
    self.staticHoldAnimation = false

    self.danceSpeed = 2
    self.danced = false

    self.icon = "face"

    self.cameraPosition = {x = 0, y = 0}

    self.script = Script("characters/" .. char)
    if (self.script.closed) then self.script = Script("characters/bf") end
    self.script.variables["self"] = self

    self.script:call("create")

    if self.isPlayer ~= self.flipX then
        self.__reverseDraw = true
        self:switchAnim("singLEFT", "singRIGHT")
        self:switchAnim("singLEFTmiss", "singRIGHTmiss")
    end
    if self.isPlayer then self.flipX = not self.flipX end

    self:dance()
    self:finish()

    self.script:call("postCreate")
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
    self.script:call("update", dt)
    Character.super.update(self, dt)
    self.script:call("postUpdate", dt)
end

function Character:draw()
    self.script:call("draw")
    if self.__reverseDraw then self.offset.x = self.offset.x * -1 end
    Character.super.draw(self)
    if self.__reverseDraw then self.offset.x = self.offset.x * -1 end
    self.script:call("postDraw")
end

function Character:beat(b)
    self.script:call("beat", b)

    if self.lastHit > 0 then
        if self.lastHit + math.max(1, math.floor(math.round(self.singDuration) / 2 - 1)) <= PlayState.inst.currentBeatFloat then
            self:dance()
            self.lastHit = 0
        end
    elseif b % self.danceSpeed == 0 then
        self:dance(self.danceSpeed < 2)
    end
    self.script:call("postBeat", b)
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

function Character:sing(dir, miss, hold)
    if not self.staticHoldAnimation or not hold or self.lastSing ~= dir or
        self.lastSing == nil or self.lastMiss ~= miss or self.lastMiss == nil then
        local anim = "sing" .. string.upper(Note.directions[dir + 1])
        if miss then anim = anim .. "miss" end
        self:playAnim(anim, true)

        self.lastSing = dir
        self.lastMiss = miss
    end

    self.lastHit = PlayState.inst.currentBeatFloat
end

function Character:dance(force)
    if self.__animations and self.script:callReturn("dance") then
        self.lastSing = nil
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
