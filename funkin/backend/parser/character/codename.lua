local codename = {name = "Codename"}

function codename.parse(data, name)
    local char = Parser.getDummyChar()

    for _, anim in ipairs(data.children) do
        if anim.name == "anim" then
            local indices = {}
            if anim.attrs.indices ~= nil then
                local temp = anim.attrs.indices:split("..")
                if #temp >= 2 then
                    for i = tonumber(temp[1]), tonumber(temp[2]) do
                        table.insert(indices, i)
                    end
                else
                    temp = anim.attrs.indices:split(",")
                    for _, i in ipairs(temp) do
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

    Parser.pset(char, "position", {tonumber(data.attrs.x) or 0, tonumber(data.attrs.y) or 0})
    Parser.pset(char, "camera_points", {tonumber(data.attrs.camx) - 150 or 0, tonumber(data.attrs.camy) - 100 or 0})
    Parser.pset(char, "sing_duration", tonumber(data.attrs.holdTime) or 4)
    Parser.pset(char, "dance_beats", tonumber(data.attrs.interval))

    if data.attrs.flipX ~= nil then
        Parser.pset(char, "flip_x", tobool(data.attrs.flipX))
    end
    Parser.pset(char, "icon", data.attrs.icon or name)
    Parser.pset(char, "sprite", "characters/" .. (data.attrs.sprite or name))
    if data.attrs.antialiasing ~= nil then
        Parser.pset(char, "antialiasing", tobool(data.attrs.antialiasing))
    end
    Parser.pset(char, "scale", tonumber(data.attrs.scale) or 1)

	if data.attrs.color ~= nil then
    	char.color = data.attrs.color
	end

    return char
end

return codename
