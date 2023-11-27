local Highscore = {
    scores = {
        songs = {},
        weeks = {}
    }
}

function Highscore.saveScore(song, score, diff)
    local formatSong = song .. '-' .. diff

    if Highscore.scores.songs[formatSong] then
        if Highscore.scores.songs[formatSong] < score then
            Highscore.scores.songs[formatSong] = score
        end
    else
        Highscore.scores.songs[formatSong] = score
    end
end

function Highscore.saveWeekScore(week, score, diff)
    local formatSong = week .. '-' .. diff

    if Highscore.scores.weeks[formatSong] then
        if Highscore.scores.weeks[formatSong] < score then
            Highscore.scores.weeks[formatSong] = score
        end
    else
        Highscore.scores.weeks[formatSong] = score
    end
end

function Highscore.getScore(song, diff)
    local formatSong = song .. '-' .. diff

    if Highscore.scores.songs[formatSong] == nil then
        Highscore.scores.songs[formatSong] = 0
    end

    return Highscore.scores.songs[formatSong]
end

function Highscore.getWeekScore(week, diff)
    local formatSong = week .. '-' .. diff

    if Highscore.scores.weeks[formatSong] == nil then
        Highscore.scores.weeks[formatSong] = 0
    end

    return Highscore.scores.weeks[formatSong]
end

return Highscore