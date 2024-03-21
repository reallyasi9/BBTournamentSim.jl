function score(picks, winners, values)
    score = 0
    for (winner, pick, value) in zip(winners, picks, values)
        if winner == pick
            score += value
        end
    end
    return score
end

function points(picks::Picks, tournament::Tournament)
    score_now = zero(P)
    best_possible = zero(P)
    for pick in picks
        if team(pick) == winner(tournament, game(pick))
            val = value(tournament, game(pick))
            score_now += val
            best_possible += val
        elseif !is_eliminated(tournament, team(pick))
            best_possible += value(tournament, game(pick))
        end
    end
    return (score_now, best_possible)
end