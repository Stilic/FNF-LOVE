local SoundManager = {list = {}}
local soundDataCache = {}

-- `asset` can be either a SoundData instance or a string. `stream` is ignored if `asset` isn't a string.
function SoundManager.play(asset, stream, volume, looped, autoDestroy, onComplete)
  local source
  if type(asset) == "string" then
    if stream then
      source = love.audio.newSource(asset, "stream")
    else
      local path = asset
      if string.startsWith(path, "./") then
        path = string.sub(path, 3)
      end
      if string.endsWith(path, "/") then
        path = string.sub(path, 1, -2)
      end
      if soundDataCache[path] then
        asset = soundDataCache[path]
      else
        asset = love.sound.newSoundData(path)
        soundDataCache[path] = asset
      end
    end
  end
  if not source then
    source = love.audio.newSource(asset)
  end
  if volume ~= nil then
    source:setVolume(volume)
  end
  if looping ~= nil then
    source:setLooping(looping)
  end
  table.insert(SoundManager.list, source)
  source:play()
  return source
end

function SoundManager.destroy()
  for _, s in pairs(SoundManager.list) do
    s:release()
  end
end

return SoundManager
