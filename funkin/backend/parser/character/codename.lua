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
                else
                    local temp2 = anim.attrs.indices:split(",")
                    for _, i in ipairs(temp2) do
                        table.insert(indices, tonumber(i))
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

    Parser.pset(char, "position", {tonumber(data.character.attrs.x) or 0, tonumber(data.character.attrs.y) or 0})
    Parser.pset(char, "camera_points", {tonumber(data.character.attrs.camx) or 0, tonumber(data.character.attrs.camy) or 0})
    Parser.pset(char, "sing_duration", tonumber(data.character.attrs.holdTime) or 4)
    Parser.pset(char, "dance_beats", tonumber(data.character.attrs.interval))

    Parser.pset(char, "flip_x", data.character.attrs.flipX == "true" or false)
    Parser.pset(char, "icon", data.character.attrs.icon)
    Parser.pset(char, "sprite", data.character.attrs.sprite)
    Parser.pset(char, "antialiasing", data.character.attrs.antialiasing == "true" or true)
    Parser.pset(char, "scale", tonumber(data.character.attrs.scale))

    char.color = data.character.attrs.color

    return char
end

return codename
