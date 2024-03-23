using ArgParse
using BBSim
using JSON3
using CSV
using Parquet2
using StatsBase

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
    ranks = competerank(scores_now)
    ranks_best = competerank(scores_best)
    

    if !isnothing(options["rankfile"])
        open(options["rankfile"], "w") do io
            CSV.write(io, (owner=owners, score=scores_now, rank=ranks, best_score=scores_best, best_rank=ranks_best))
        end
    else
        CSV.write(stdout, (owner=owners, score=scores_now, rank=ranks, best_score=scores_best, best_ranks=ranks_best))
    end
end

if !isinteractive()
    main(ARGS)
end