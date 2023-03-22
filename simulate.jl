using ArgParse
using BBSim
using YAML

function cluster_ties(sorted::Vector{Pair})
    ties = Vector{eltype(sorted)}[]
    prev = last(first(sorted))
    cache = Vector{eltype(sorted)}()
    for (key, val) in sorted
        if val != prev
            push!(ties, copy(cache))
            empty!(cache)
            prev = val
        end
        push!(cache, key=>val)
    end
    push!(ties, cache)
    return ties
end

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--picks", "-p"
            help = "Picks data in YAML format"
            required = true
        "--values", "-v"
            help = "Round values data in YAML format"
            required = true
        "--predictions", "-f"
            help = "FiveThirtyEight probability data in YAML format"
            required = true
        "--teamorder", "-t"
            help = "Team tournament order in YAML format"
            required = true
        # "--seed", "-s"
        #     help = "Random seed"
        #     arg_type = Int
        #     default = 42
        "--simulations", "-N"
            help = "Number of simulations to run"
            arg_type = Int
            default = 1_000_000
        "--histfile", "-o"
            help = "Path to output rank histogram in YAML format (default: write to STDOUT)"
        "--matrixfile", "-m"
            help = "Path to output excite-o-matic matrix file in YAML format (default: write to STDOUT)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)
    
    team_order = YAML.load_file(options["teamorder"])
    vals = YAML.load_file(options["values"])
    picks_data = YAML.load_file(options["picks"])
    fte_data = YAML.load_file(options["predictions"])

    tournament = BBSim.make_tournament(team_order, fte_data)
    
    # Note: places are fractional in case of ties
    ranks_hist = Dict{String, Vector{Float64}}()
    play_in_mask = BBSim.get_play_in_games(tournament)
    # (game_number => (winning_team => picker) => wins
    game_team_picker_wins = Dict{Pair{Int,Pair{String,String}},Float64}()

    n_sims = options["simulations"]
    for _ in 1:n_sims
        sim_winners = BBSim.simulate_wins(tournament)
        scores = [picker => BBSim.score(picks, sim_winners, vals) for (picker, picks) in picks_data]
        sort!(scores, by=last, rev=true)
        score_ties = cluster_ties(scores)
        for cluster in score_ties
            n_ties = length(cluster)
            for (i, picker_score) in enumerate(cluster)
                v = get!(ranks_hist, first(picker_score), zeros(Float64, length(scores)))
                v[i] += 1 / n_ties
            end
        end

        # How this works:
        # If team T wins, we want to know how many times player P comes in first.
        # The games will be paired back up in plot_matrix.
        first_places = first(score_ties[1])
        for (game, winner) in zip(tournament[play_in_mask], sim_winners[play_in_mask])
            n_ties = length(first_places)
            for (first_place, _) in first_places
                g_t_p = game.number => winner => first_place
                game_team_picker_wins[g_t_p] = get!(game_team_picker_wins, g_t_p, 0.) + 1 / n_ties
            end
        end
    end

    p_ranks = Dict(key => vals ./ n_sims for (key, vals) in ranks_hist)

    if isnothing(options["histfile"])
        YAML.write(stdout, p_ranks)
    else
        YAML.write_file(options["histfile"], p_ranks)
    end

    # to compute the proper probability, first need the number of times a team won a game
    # (each team only plays one play-in game, so we don't need the game number here)
    team_wins = Dict{String, Float64}()
    for (g_t_p, wins) in game_team_picker_wins
        _, (winner, _) = g_t_p
        team_wins[winner] = get!(team_wins, winner, 0) + wins
    end

    # picker => (game_number => winner) => prob. of coming in first place given winner of game_number
    picker_game_team_probs = Dict{String, Dict{Int, Dict{String, Float64}}}()
    for (g_t_p, wins) in game_team_picker_wins
        game, (winner, picker) = g_t_p
        
        game_team_probs = get!(picker_game_team_probs, picker, Dict{Int, Dict{String, Float64}}())
        team_probs = get!(game_team_probs, game, Dict{String, Float64}())
        team_probs[winner] = wins / team_wins[winner]
    end

    if isnothing(options["matrixfile"])
        YAML.write(stdout, picker_game_team_probs)
    else
        YAML.write_file(options["matrixfile"], picker_game_team_probs)
    end

end

if !isinteractive()
    main()
end