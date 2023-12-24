local pcall = _G.pcall

---@class Sound:Basic
local Sound = Basic:extend("Sound")

function Sound:new()
	Sound.super.new(self)

	self.__indexFuncs = {}
	self.visible = false

	self:reset()
end

function Sound:reset(destroySound)
	if self.__source and (destroySound ~= nil and destroySound or true) then
		self:stop()
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

function Sound:play(volume, looped, pitch)
	if volume ~= nil then self:setVolume(volume) end
	if looped ~= nil then self:setLooping(looped) end
	if pitch ~= nil then self:setPitch(pitch) end

	self.__paused = false
	pcall(self.__source.play, self.__source)
	return self
end

function Sound:pause()
	self.__paused = true
	pcall(self.__source.pause, self.__source)
	return self
end

function Sound:stop()
	self.__paused = true
	pcall(self.__source.stop, self.__source)
	return self
end

function Sound:isPlaying()
	local success, isPlaying = pcall(self.__source.isPlaying, self.__source)
	if success then return isPlaying end
	return nil
end

function Sound:isFinished()
	return not self.__paused and not self.__source:isLooping() and
		not self:isPlaying()
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
	if love.autoPause and not self:isFinished() then
		if focus then
			if self.__wasPlaying ~= nil and self.__wasPlaying then
				self:play()
			end
		else
			self.__wasPlaying = self:isPlaying()
			if self.__wasPlaying ~= nil and self.__wasPlaying then
				self:pause()
			end
		end
	end
end

function Sound:kill()
	Sound.super.kill(self)
	self:reset(self.autoDestroy)
end

function Sound:destroy()
	if self.__source then
		self:stop()
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
							prop = function (_, ...)
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
