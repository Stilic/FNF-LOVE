local SoundManager = {list = {}}

-- `soundAsset` can be either a SoundData instance or an existing Source.
function SoundManager.play(soundAsset, volume, looped, autoRelease, onComplete)
	
    source:setVolume(volume)
    table.insert(SoundManager.list, source)
end

return SoundManager
