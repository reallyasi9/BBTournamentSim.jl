using ArgParse
using BBSim
using InlineStrings
using YAML
using CairoMakie

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
            default = 100_000
        "--outfile", "-o"
            help = "Path to output plot file (format determined by extension)"
            default = "simulation.svg"
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
    
    ranks = Dict{String, Vector{Int}}()

    n_sims = options["simulations"]

    for _ in 1:n_sims
        sim_winners = BBSim.simulate_wins(tournament)
        scores = [picker => BBSim.score(picks, sim_winners, vals) for (picker, picks) in picks_data]
        sort!(scores, by=last, rev=true)
        for (i,picker_score) in enumerate(scores)
            v = get!(ranks, first(picker_score), Vector{Int}())
            push!(v, i)
        end

    end

    fig = BBSim.plot_ranks(ranks)
    save(options["outfile"], fig)
end

if !isinteractive()
    main()
end