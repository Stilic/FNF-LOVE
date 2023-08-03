local Receptor = Sprite:extend()

function Receptor:new(x, y, data, player)
    Receptor.super.new(self, x, y)
    self:setFrames(paths.getSparrowAtlas("skins/normal/NOTE_assets"))

    self.data = data
    self.player = player

    self.__timer = 0

    self:setGraphicSize(math.floor(self.width * 0.7))

    local dir = Note.directions[data + 1]
    self:addAnimByPrefix("static", "arrow" .. string.upper(dir), 24, false)
    self:addAnimByPrefix("pressed", dir .. " press", 24, false)
    self:addAnimByPrefix("confirm", dir .. " confirm", 24, false)

    self:updateHitbox()
end

function Receptor:groupInit()
    self.x = self.x - Note.swagWidth * 2 + Note.swagWidth * self.data
    self:setScrollFactor(0)
    self:play("static")
end

function Receptor:update(dt)
    if self.__timer > 0 then
        self.__timer = self.__timer - dt
        if self.__timer <= 0 then
            self.__timer = 0
            self:play("static")
        end
    end
    Receptor.super.update(self, dt)
end

function Receptor:play(anim, force)
    Receptor.super.play(self, anim, force)

    self:centerOffsets()
    self:centerOrigin()

    if anim == "confirm" then
        if self.data == 0 then
            self.offset.x, self.offset.y = self.offset.x - 1, self.offset.y - 3
        elseif self.data == 1 then
            self.offset.x, self.offset.y = self.offset.x - 2, self.offset.y - 2
        elseif self.data == 2 then
            self.offset.x, self.offset.y = self.offset.x - 1,
                                           self.offset.y - 0.5
        elseif self.data == 3 then
            self.offset.x = self.offset.x - 1.5
        end
    end
end

function Receptor:confirm(time)
    self:play("confirm", true)
    self.__timer = time
end

return Receptor
