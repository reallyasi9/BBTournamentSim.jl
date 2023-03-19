using ArgParse
using BBSim
using InlineStrings
using YAML
using CairoMakie

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--pickem", "-p"
            help = "Pick'Em picks data in CSV format"
            required = true
        "--fivethirtyeight", "-f"
            help = "FiveThirtyEight probability data in CSV format"
            required = true
        "--teamorder", "-t"
            help = "Team tournament order in YAML format"
            required = true
        "--teammap", "-m"
            help = "Team name mapping from FiveThirtyEight to Pick'Em in YAML format"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)
    
    if !isnothing(options["teammap"])
        team_map = YAML.load_file(options["teammap"])
    else
        team_map = Dict{String,String}()
    end

    team_order = YAML.load_file(options["teamorder"])

    picks_data, vals = BBSim.parse_pickem(options["pickem"])
    fte_data = BBSim.parse_fivethirtyeight(options["fivethirtyeight"]; team_name_remap=team_map)

    # println(picks_data)
    # println(vals)
    # println(fte_data)

    tournament = BBSim.make_tournament(team_order, fte_data)
    
    tournament_winners = Dict{String31, Int}()
    final_fours = Dict{String31, Int}()
    ranks = Dict{String, Vector{Int}}()
    for _ in 1:100_000
        sim_winners = BBSim.simulate_wins(tournament)
        winner = last(sim_winners)
        tournament_winners[winner] = get!(tournament_winners, winner, 0) + 1
        final_four = sim_winners[end-6:end-3]
        for team in final_four
            final_fours[team] = get!(final_fours, team, 0) + 1
        end

        scores = [picker => BBSim.score(picks, sim_winners, vals) for (picker, picks) in picks_data]
        sort!(scores, by=last, rev=true)
        for (i,picker_score) in enumerate(scores)
            v = get!(ranks, first(picker_score), Vector{Int}())
            push!(v, i)
        end

    end

    # println(ranks)
    println(tournament_winners)
    # println(final_fours)

    fig = BBSim.plot_ranks(ranks)
    save("ranks.svg", fig)
end

if !isinteractive()
    main()
end