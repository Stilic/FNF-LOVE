local fpsFormat = "FPS: %d\nRAM: %s | VRAM: %s\nDRAWS: %d"
local fpsParallelFormat = "FPS: %d | UPDATE: %d \nRAM: %s | VRAM: %s\nDRAWS: %d"

local __step__, __quit__ = "step", "quit"
local consolas, real_fps = love.graphics.newFont('assets/fonts/consolas.ttf', 14), 0
function love.run()
    local _, _, modes = love.window.getMode()
    love.FPScap, love.unfocusedFPScap = math.max(modes.refreshrate, 60), 8
    love.showFPS = false
    love.autoPause = flags.InitialAutoFocus
    love.parallelUpdate = flags.InitialParallelUpdate

    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    love.timer.step()

    collectgarbage()
    collectgarbage(__step__)

    local _stats, _update, _fps, _ram, _vram, _text
    local function draw()
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        love.draw()

        if love.showFPS then
            _stats, _update = love.graphics.getStats(), love.timer.getUpdateFPS()
            _fps = math.min(love.parallelUpdate and real_fps or _update, love.FPScap)
            _ram, _vram = math.countbytes(collectgarbage("count") * 0x400), math.countbytes(_stats.texturememory)
            _text = love.parallelUpdate and
                    fpsParallelFormat:format(_fps, _update, _ram, _vram, _stats.drawcalls) or
                    fpsFormat:format(_fps, _ram, _vram, _stats.drawcalls)

            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.printf(_text, consolas, 8, 8, 300, "left", 0)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(_text, consolas, 6, 6, 300, "left", 0)
        end

        love.graphics.present()
    end

    local polledEvents, _defaultEvents = {}, {}
    local fpsUpdateFrequency, prevFpsUpdate, timeSinceLastFps, frames = 1, 0, 0, 0
    local firstTime, fullGC, focused, dt, real_dt, lowfps = true, true, false, 0
    local nextclock, clock, cap = 0, 0, 0

    return function()
        love.event.pump()
        table.merge(polledEvents, _defaultEvents)
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == __quit__ and not love.quit() then
                return a or 0
            end
            _defaultEvents[name], polledEvents[name] = false, true
            love.handlers[name](a, b, c, d, e, f)
            --[[
            if name:sub(1,5) == "mouse" and name ~= "mousefocus" then
                love.handlers["touch"..name:sub(6)](a, b, c, d, e, f)
            end
            ]]
        end

        real_dt = love.timer.step()
        lowfps = real_dt - dt > 0.04
        if not polledEvents.lowmemory and ((fullGC and not focused) or lowfps) then
            love.handlers.lowmemory()
            dt, fullGC = lowfps and dt + 0.04 or real_dt, false
        else
            dt, fullGC = real_dt, true
        end

        focused = firstTime or love.window.hasFocus()
        cap = 1 / (focused and love.FPScap or love.unfocusedFPScap)

        if focused or not love.autoPause then
            love.update(dt)
            if love.graphics.isActive() then
                if love.parallelUpdate then
                    clock = love.timer.getTime()
                    if clock + real_dt > nextclock then
                        draw()
                        nextclock = cap + clock
                        timeSinceLastFps, frames = clock - prevFpsUpdate, frames + 1
                        if timeSinceLastFps > fpsUpdateFrequency then
                            real_fps, frames = math.round(frames / timeSinceLastFps), 0
                            prevFpsUpdate = clock
                        end
                    end
                else
                    draw()
                end
            end
        end

        collectgarbage(__step__)

        if not love.parallelUpdate or not focused then
            love.timer.sleep(cap - real_dt)
        else
            if real_dt < 0.001 then
                love.timer.sleep(0.001)
            end
        end
        firstTime = false
    end
end

local _ogGetFPS = love.timer.getFPS

---@return number -- Returns the current draws FPS.
function love.timer.getDrawFPS()
    return game.parallelUpdate and real_fps or _ogGetFPS()
end

---@return number -- Returns the current updates FPS.
love.timer.getUpdateFPS = _ogGetFPS

---@return number -- Returns the current frames per second.
love.timer.getFPS = love.timer.getDrawFPS