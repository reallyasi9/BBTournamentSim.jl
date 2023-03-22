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
    picker_wins_by_team_wins = Dict{String, Dict{String, Int}}()

    n_sims = options["simulations"]
    for _ in 1:n_sims
        sim_winners = BBSim.simulate_wins(tournament)
        scores = [picker => BBSim.score(picks, sim_winners, vals) for (picker, picks) in picks_data]
        sort!(scores, by=last, rev=true)
        for (i, picker_score) in enumerate(scores)
            v = get!(ranks_hist, first(picker_score), zeros(Int, length(scores)))
            v[i] += 1
        end

        first_place = first(scores[1])
        for winner in sim_winners[play_in_mask]
            d = get!(picker_wins_by_team_wins, first_place, Dict{String, Int}())
            d[winner] = get!(d, winner, 0) + 1
        end
    end

    p_ranks = Dict(key => vals ./ n_sims for (key, vals) in ranks_hist)

    if isnothing(options["histfile"])
        YAML.write(stdout, p_ranks)
    else
        YAML.write_file(options["histfile"], p_ranks)
    end

    p_matrix = Dict{String, Dict{String, Float64}}()
    for (picker, picker_team_wins) in picker_wins_by_team_wins
        p_teams = Dict(team => wins / ranks_hist[picker][1] for (team, wins) in picker_team_wins)
        p_matrix[picker] = p_teams
    end

    if isnothing(options["matrixfile"])
        YAML.write(stdout, p_matrix)
    else
        YAML.write_file(options["matrixfile"], p_matrix)
    end

end

if !isinteractive()
    main()
end