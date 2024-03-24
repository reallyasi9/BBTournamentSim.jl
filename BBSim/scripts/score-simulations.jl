using ArgParse
using BBSim
using JSON3
using CSV
using Parquet2
using Statistics
using DataFrames

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "tournament"
            help = "Tournament JSON file"
            required = true
        "posteriors"
            help = "Picks JSON file"
            required = true
        "simulations"
            help = "Simulations parquet file"
            required = true
        "--expecto", "-e"
            help = "Path to output expected values file (CSV format)"
        "--exciteo", "-x"
            help = "Path to output expected values conditional on game winners file (CSV format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    tournament = open(options["tournament"], "r") do io
        JSON3.read(io, BBSim.Tournament)
    end

    posteriors = DataFrame(Parquet2.readfile(options["posteriors"]))
    # parquet makes subsetting difficult
    transform!(posteriors, :owner => ByRow(String) => :owner)
    simulations = DataFrame(Parquet2.readfile(options["simulations"]))
    n_simulations = maximum(simulations[!, :simulation])

    # find games in the tournament that do not have winners but do have teams
    next_up = Vector{Int}()
    for game in 1:length(tournament)
        isnothing(BBSim.winner(tournament, game)) || continue
        (isnothing(BBSim.team(tournament, game, 1)) || isnothing(BBSim.team(tournament, game, 2))) && continue
        push!(next_up, game)
    end

    expecto = combine(
        groupby(posteriors, [:owner]),
        :points => mean => :points_mean,
        :points => minimum => :points_now,
        :points => (x -> quantile(x, 0.25)) => :points_q25,
        :points => median => :points_median,
        :points => (x -> quantile(x, 0.75)) => :points_q75,
        :points => maximum => :points_max,
        :ranks => mean => :rank_mean,
        :ranks => maximum => :rank_now,
        :ranks => (x -> quantile(x, 0.75)) => :rank_q25,
        :ranks => median => :rank_median,
        :ranks => (x -> quantile(x, 0.25)) => :rank_q75,
        :ranks => minimum => :rank_max,
        :ranks => (x -> count(==(1), x) / n_simulations) => :p_win,
    )

    if !isnothing(options["expecto"])
        open(options["expecto"], "w") do io
            CSV.write(io, expecto)
        end
    else
        CSV.write(stdout, expecto)
    end

    subset!(simulations, :game => ByRow(in(next_up)))
    subset!(posteriors, :ranks => ByRow(==(1)))
    exciteo = combine(
        groupby(leftjoin(posteriors, simulations, on=:simulation), [:owner, :game, :winner]),
        nrow => :victories
    )
    transform!(exciteo, :victories => ByRow(x -> x/n_simulations) => :conditional_p_win)

    if !isnothing(options["exciteo"])
        open(options["exciteo"], "w") do f
            Parquet2.writefile(f, exciteo)
        end
    else
        print(first(exciteo, 30; view=true))
        println("...")
        print(last(exciteo, 30; view=true))
    end
end

if !isinteractive()
    main(ARGS)
end