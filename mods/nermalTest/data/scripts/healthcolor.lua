local charColor = {
    bf = "#31B0D1",
    nermal = "#94918A"
}

function postCreate()
    state.healthBar.color = Color.fromString(charColor[state.boyfriend.char]) or Color.GREEN
    state.healthBar.color.bg = Color.fromString(charColor[state.dad.char]) or Color.RED
end