local psych = {name = "Psych"}

function psych.parse(data)
    local char = Parser.getDummyChar()

	Parser.pset(char, "sprite", data.image)
    Parser.pset(char, "icon", data.healthicon)
    Parser.pset(char, "antialiasing", not data.no_antialiasing)
    Parser.pset(char, "camera_points", data.camera_position)

    char.animations = {}
    for _, anim in pairs(data.animations) do
        local animation = {
            anim.anim,
            anim.name or '',
            anim.indices or {},
            anim.fps or 24,
            anim.loop or false,
            anim.offsets
        }

        table.insert(char.animations, animation)
    end

    char.color = string.format("#%02x%02x%02x",
        data.healthbar_colors[1],
        data.healthbar_colors[2],
        data.healthbar_colors[3],
    )

    return char
end

return psych