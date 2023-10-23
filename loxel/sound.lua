local Sound = Basic:extend()

function Sound:new()
    Sound.super.new(self)

    self.__indexFuncs = {}
    self.visible = false

    self:reset()
end

function Sound:reset(destroySound)
    if self.__source and (destroySound ~= nil and destroySound or true) then
        pcall(self.__source.stop, self.__source)
        self.__source = nil
        self.__indexFuncs = {}
    end

    self.__paused = true
    self.__wasPlaying = false

    self.persist = false
    self.autoDestroy = false

    self.active = false

    self.onComplete = nil
end

function Sound:load(asset)
    self:reset()

    self.__source = asset:typeOf("SoundData") and love.audio.newSource(asset) or
                        asset
    self.active = true

    return self
end

function Sound:play()
    self.__paused = false
    return self.__source:play()
end

function Sound:pause()
    self.__paused = true
    return self.__source:pause()
end

function Sound:stop()
    self.__paused = true
    self.__source:stop()
end

function Sound:isFinished()
    return not self.__source:isLooping() and not self.__paused and
               not self.__source:isPlaying()
end

function Sound:update()
    if self:isFinished() then
        if self.onComplete then self.onComplete() end
        if not self.__source:isLooping() then
            if self.autoDestroy then
                self:kill()
            else
                self:stop()
            end
        end
    end
end

function Sound:onFocus(focus)
    if focus then
        if self.__wasPlaying then self:play() end
    else
        self.__wasPlaying = self.__source:isPlaying()
        if self.__wasPlaying then self:pause() end
    end
end

function Sound:kill()
    Sound.super.kill(self)
    self:reset(self.autoDestroy)
end

function Sound:destroy()
    if self.__source then
        pcall(self.__source.stop, self.__source)
        self.__source = nil
        self.__indexFuncs = {}
    end
    self.onComplete = nil

    Sound.super.destroy(self)
end

function Sound:__index(key)
    if key == "release" then
        return nil
    else
        local prop = rawget(self, key)
        if not prop then
            prop = getmetatable(self)
            if prop[key] then
                prop = prop[key]
            else
                local source = rawget(self, "__source")
                if source then
                    prop = source[key]
                    if prop and type(prop) == "function" then
                        local indexProps = rawget(self, "__indexFuncs")
                        prop = indexProps[key]
                        if not prop then
                            prop = function(_, ...)
                                return source[key](source, ...)
                            end
                            indexProps[key] = prop
                        end
                    end
                else
                    prop = nil
                end
            end
        end
        return prop
    end
end

return Sound
