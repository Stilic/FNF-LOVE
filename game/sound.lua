local Sound = Object:extend()
local indexSourceProps = {}

function Sound:new(asset)
    self.__source = asset:typeOf("SoundData") and love.audio.newSource(asset) or
                        asset

    self.__paused = true
    self.__wasPlaying = false
    self.__oldVolume = nil

    self.onComplete = nil
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
    self:pause()
    self.__source:stop()
end

function Sound:mute()
    if self.__oldVolume == nil then
        self.__oldVolume = self.__source:getVolume()
        self.__source:setVolume(0)
    end
end

function Sound:unmute()
    if self.__oldVolume ~= nil then
        self.__source:setVolume(self.__oldVolume)
        self.__oldVolume = nil
    end
end

function Sound:isFinished()
    return not self.__source:isLooping() and not self.__paused and
               not self.__source:isPlaying()
end

function Sound:update()
    if self:isFinished() then
        self.__paused = true
        if self.onComplete then self.onComplete() end
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

function Sound:release()
    self.__paused = true
    self.__wasPlaying = false
    self.__oldVolume = nil

    self.onComplete = nil

    self.__source:stop()
    self.__source:release()
    self.__source = nil
end

function Sound:__index(key)
    local prop = rawget(self, key)
    if not prop then
        prop = getmetatable(self)
        if prop[key] then
            prop = prop[key]
        else
            local source = rawget(self, "__source")
            prop = source[key]
            if prop and type(prop) == "function" then
                prop = indexSourceProps[key]
                if not prop then
                    prop = function(_, ...)
                        return source[key](source, ...)
                    end
                    indexSourceProps[key] = prop
                end
            end
        end
    end
    return prop
end

return Sound
