using ArgParse
using BBSim
using YAML

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
    
    ranks_hist = Dict{String, Vector{Int}}()
    play_in_mask = BBSim.get_play_in_games(tournament)
    # (game_number => (winning_team => picker)) => wins
    game_team_picker_wins = Dict{Pair{Int,Pair{String,String}},Int}()

    n_sims = options["simulations"]
    for _ in 1:n_sims
        sim_winners = BBSim.simulate_wins(tournament)
        scores = [picker => BBSim.score(picks, sim_winners, vals) for (picker, picks) in picks_data]
        sort!(scores, by=last, rev=true)
        for (i, picker_score) in enumerate(scores)
            v = get!(ranks_hist, first(picker_score), zeros(Int, length(scores)))
            v[i] += 1
        end

        # How this works:
        # If team T wins, we want to know how many times player P comes in first.
        # The games will be paired back up in plot_matrix.
        first_place = first(scores[1])
        for (game, winner) in zip(tournament[play_in_mask], sim_winners[play_in_mask])
            g_t_p = game.number => winner => first_place
            game_team_picker_wins[g_t_p] = get!(game_team_picker_wins, g_t_p, 0) + 1
        end
    end

    p_ranks = Dict(key => vals ./ n_sims for (key, vals) in ranks_hist)

    if isnothing(options["histfile"])
        YAML.write(stdout, p_ranks)
    else
        YAML.write_file(options["histfile"], p_ranks)
    end

    g_matrix = Dict{Int, Dict{String, Dict{String, Float64}}}()
    for (game_team_picker, wins) in game_team_picker_wins
        game, (team, picker) = game_team_picker
        t_matrix = get!(g_matrix, game, Dict{String, Dict{String, Float64}}())
        p_matrix = get!(t_matrix, team, Dict{String, Float64}())
        p_matrix[picker] = wins / ranks_hist[picker][1]
    end

    if isnothing(options["matrixfile"])
        YAML.write(stdout, g_matrix)
    else
        YAML.write_file(options["matrixfile"], g_matrix)
    end

end

if !isinteractive()
    main()
end