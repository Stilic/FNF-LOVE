local psych = {name = "Psych"}

function psych.parse(data)
    local char = Parser.getDummyChar()

	Parser.pset(char, "sprite", data.image)
    Parser.pset(char, "icon", data.healthicon)
    Parser.pset(char, "antialiasing", not data.no_antialiasing)
    Parser.pset(char, "camera_points", data.camera_position)
	Parser.pset(char, "flip_x", data.flip_x)

    char.animations = {}
    for _, anim in pairs(data.animations) do
        local animation = {
            anim.anim,
            anim.name,
            anim.indices,
            anim.fps,
            anim.loop,
            anim.offsets
        }

        table.insert(char.animations, animation)
    end

    if data.healthbar_colors ~= nil then
        char.color = string.format("#%02x%02x%02x",
            data.healthbar_colors[1],
            data.healthbar_colors[2],
            data.healthbar_colors[3]
        ):upper()
    end

    return char
end

return psych
