using ArgParse
using BBSim
using JSON3
using CSV
using Parquet2
using StatsBase
using DataFrames

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "tournament"
            help = "Tournament JSON file"
            required = true
        "picks"
            help = "Picks JSON file"
            required = true
        "simulations"
            help = "Simulations parquet file"
        "--rankfile", "-r"
            help = "Path to output pick rank-score file (CSV format)"
        "--posterior", "-p"
            help = "Posterior pick rank-score file (parquet format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    tournament = open(options["tournament"], "r") do io
        JSON3.read(io, BBSim.Tournament)
    end

    picks = open(options["picks"], "r") do io
        JSON3.read(io, Vector{BBSim.Picks})
    end

    if isnothing(options["simulations"])
        simulations = nothing
    else
        simulations = Parquet2.readfile(options["simulations"])
    end

    scores = BBSim.points.(picks, Ref(tournament))
    scores_now = first.(scores)
    scores_best = last.(scores)
    owners = BBSim.owner.(picks)
    ranks = competerank(scores_now; rev=true)

    if !isnothing(options["rankfile"])
        open(options["rankfile"], "w") do io
            CSV.write(io, (owner=owners, rank=ranks, score=scores_now, best_score=scores_best))
        end
    else
        CSV.write(stdout, (owner=owners, rank=ranks, score=scores_now, best_score=scores_best))
    end

    isnothing(simulations) && return

    pick_matrix = stack([BBSim.id.(v) for v in BBSim.picks.(picks)])
    df = DataFrame(simulations; copycols=false)
    sort!(df, [:simulation, :game])
    score_df = combine(
        groupby(df, :simulation),
        [:winner, :value] => ((w, v) -> score_sim(pick_matrix, owners, w, v)) => AsTable
    )

    if !isnothing(options["posterior"])
        open(options["posterior"], "w") do f
            Parquet2.writefile(f, score_df)
        end
    else
        print(first(score_df, 30; view=true))
        println("...")
        print(last(score_df, 30; view=true))
    end
end

function score_sim(picks, owners, winners, values)
    points = vec(sum((picks .== winners) .* values; dims=1))
    ranks = competerank(points; rev=true)
    return (owner=owners, points=points, rank=ranks)
end

if !isinteractive()
    main(ARGS)
end