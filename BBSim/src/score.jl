function score(picks, winners, values)
    score = 0
    for (winner, pick, value) in zip(winners, picks, values)
        if winner == pick
            score += value
        end
    end
    return score
end

function points(p::Picks, tournament::Tournament)
    score_now = 0
    best_possible = 0
    for (g, team) in pairs(picks(p))
        val = value(tournament, g)
        if team == winner(tournament, g)
            score_now += val
            best_possible += val
        elseif !is_eliminated(tournament, team)
            best_possible += val
        end
    end
    return (score_now, best_possible)
end