local SoundManager = { list = Group(), music = nil }

function SoundManager.load(asset, volume, looped, autoDestroy, onComplete)
	local sound = SoundManager.list:recycle(Sound):load(asset)
	if volume ~= nil then sound:setVolume(volume) end
	if looped ~= nil then sound:setLooping(looped) end
	sound.autoDestroy = autoDestroy ~= nil and autoDestroy or true
	sound.onComplete = onComplete
	return sound
end

function SoundManager.play(...)
	return SoundManager.load(...):play()
end

function SoundManager.loadMusic(asset, volume, looped)
	if SoundManager.music then
		SoundManager.music:stop()
	else
		SoundManager.music = Sound()
		SoundManager.music.persist = true
	end

	SoundManager.music:load(asset)
	if volume ~= nil then SoundManager.music:setVolume(volume) end
	if looped == nil then
		SoundManager.music:setLooping(true)
	else
		SoundManager.music:setLooping(looped)
	end
	return SoundManager.music
end

function SoundManager.playMusic(...) return SoundManager.loadMusic(...):play() end

function SoundManager.update()
	if SoundManager.music and SoundManager.music.exists and
		SoundManager.music.active then
		SoundManager.music:update()
	end
	SoundManager.list:update()
end

function SoundManager.onFocus(focus)
	if SoundManager.music and SoundManager.music.exists and
		SoundManager.music.active then
		SoundManager.music:onFocus(focus)
	end
	for _, s in ipairs(SoundManager.list.members) do
		if s.exists then s:onFocus(focus) end
	end
end

function SoundManager.destroy(force)
	table.remove(SoundManager.list.members, function (t, i)
		local s = t[i]
		local remove = force or not s.persist
		if remove then s:destroy() end
		return remove
	end)
end

return SoundManager
