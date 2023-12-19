local charColor = {
    bf = "#31B0D1",
    bfShot = "#31B0D1",
    nermal = "#94918A",
    angrynermal = "#94918A",
    garfield = "#FF9933",
    guy = "#A357AB",
    nwrmal = "#808080"
}

function postCreate()
    state.healthBar.color = Color.fromString(charColor[state.boyfriend.char]) or Color.GREEN
    state.healthBar.color.bg = Color.fromString(charColor[state.dad.char]) or Color.RED
end