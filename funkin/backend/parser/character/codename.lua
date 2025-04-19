-- i am NOT sure if this will work

local codename = {name = "Codename"}

function codename.parse(data)
    local char = Parser.getDummyChar()

    for _, anim in ipairs(data.character.children) do
        if anim.name == "anim" then
            local indices = {}
            if anim.attrs.indices ~= nil then
                local temp = anim.attrs.indices:split("..")
                if #temp >= 2 then
                    for i = tonumber(temp[1]), tonumber(temp[2]) do
                        table.insert(indices, i)
                    end
                end
            end

            local a = {
                anim.attrs.name,
                anim.attrs.anim,
                indices,
                tonumber(anim.attrs.fps),
                anim.attrs.loop == "true",
                {tonumber(anim.attrs.x) or 0, tonumber(anim.attrs.y) or 0}
            }

            table.insert(char.animations, a)
        end
    end

    char.position = {tonumber(data.attrs.x) or 0, tonumber(data.attrs.y) or 0}
    char.camera_points = {tonumber(data.attrs.camx) or 0, tonumber(data.attrs.camy) or 0}
    char.sing_duration = tonumber(data.attrs.holdTime) or 4
    char.dance_beats = tonumber(data.attrs.interval)

    char.flip_x = data.attrs.flipX == "true" or false
    char.icon = data.attrs.icon
    char.sprite = data.attrs.sprite
    char.antialiasing = data.attrs.antialiasing == "true" or true
    char.scale = tonumber(data.attrs.scale)

    char.color = data.attrs.color

    return char
end

return codename