function score(picks, winners, values)
    score = 0
    for (winner, pick, value) in zip(winners, picks, values)
        if winner == pick
            score += value
        end
    end
    return score
end