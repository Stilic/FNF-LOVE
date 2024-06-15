local Vocals = Basic:extend("Vocals")

function Vocals:new(songData)
	Vocals.super.new(self)

	self.bf, self.dad = nil, nil
	self.volume = ClientPrefs.data.vocalVolume / 100
	self._paused = true

	local songName = paths.formatToSongPath(songData.song)
	local bfFile = paths.getVoices(songName, "Player", true)
		or paths.getVoices(songName, songData.player1, true)
		or paths.getVoices(songName, nil, true)

	local dadFile = paths.getVoices(songName, "Opponent", true)
		or paths.getVoices(songName, songData.player2, true)

	if bfFile or dadFile then
		if bfFile then
			self.bf = game.sound.load(bfFile)
			self.bf:setVolume(self.volume)
		end
		if dadFile then
			self.dad = game.sound.load(dadFile)
			self.dad:setVolume(self.volume)
		end
	end
end

function Vocals:seek(time)
	if self.bf then self.bf:seek(time) end
	if self.dad then self.dad:seek(time) end
end

function Vocals:tell()
	local bfTime, dadTime = self.bf and self.bf:tell(),
		self.dad and self.dad:tell()
	return (dadTime and (bfTime + dadTime) / 2 or bfTime)
end

function Vocals:pause()
	if self.bf then self.bf:pause() end
	if self.dad then self.dad:pause() end
	self._paused = true
end

function Vocals:play()
	if self.bf then self.bf:play() end
	if self.dad then self.dad:play() end
	self._paused = false
end

function Vocals:stop()
	if self.bf then self.bf:stop() end
	if self.dad then self.dad:stop() end
end

function Vocals:setPitch(value)
	if self.bf then self.bf:setPitch(value) end
	if self.dad then self.dad:setPitch(value) end
end

return Vocals