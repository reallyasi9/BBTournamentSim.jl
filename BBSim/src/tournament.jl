using InlineStrings

struct Game
    number::Int
    probabilities::Dict{String31,Float64}
    next_game::Ref{Game}
end

function make_tournament(team_list, probability_table)
    games = Vector{Game}(undef, 63)
    game_numbers = [
        1 => 1:32,
        2 => 33:48,
        3 => 49:56,
        4 => 57:60,
        5 => 61:62,
        6 => 63:63,
    ]
    # first 32 are special
    for gn in 1:32
        t2 = gn*2
        t1 = t2 - 1
        team1 = team_list[t1]
        team2 = team_list[t2]
        p1 = probability_table[team1 => 1]
        p2 = probability_table[team2 => 1]
        probs = Dict(team1=>p1, team2=>p2)
        games[gn] = Game(gn, probs, Ref{Game}())
        gn += 1
    end

    # round of 32 on
    for (round_number, gamelist) in game_numbers[2:end]
        start_of_this_round = first(gamelist)
        start_of_last_round = first(last(game_numbers[round_number-1]))
        println("Round $round_number starts at $start_of_this_round (last round started $start_of_last_round)")
        for gn in gamelist
            offset = gn - start_of_this_round
            play_in_games = [start_of_last_round + offset*2, start_of_last_round + offset*2 + 1]
            probs = Dict{String31,Float64}()
            println("Game $gn has play-in games $play_in_games")
            for g in play_in_games
                for p in games[g].probabilities
                    team = first(p)
                    println(" -> team $team is in play-in game $g")
                    push!(probs, team => probability_table[team => round_number])
                end
            end
            game = Game(gn, probs, Ref{Game}())
            for g in play_in_games
                games[g].next_game[] = game
            end
            games[gn] = game
            gn += 1
        end
    end

    return games
end

function simulate_wins(tournament::Vector{Game})
    competitors = Dict{Int, Set{String31}}()
    for i in 1:32
        competitors[i] = Set(keys(tournament[i].probabilities))
    end
    # To avoid altering the tournament, copy out the winners of each game
    winners = Vector{String31}(undef, 63)
    for (i,game) in enumerate(tournament)
        # pick a winner (there should be only two)
        t1, t2 = competitors[i]
        p1 = game.probabilities[t1]
        p2 = game.probabilities[t2]
        p1 = p1/(p1+p2)
        p = rand(Float64)
        if p < p1
            winner = t1
        else
            winner = t2
        end
        winners[i] = winner
        if isassigned(game.next_game)
            s = get!(competitors, game.next_game[].number, Set{String31}())
            push!(s, winner)
        end
    end
    return winners
end