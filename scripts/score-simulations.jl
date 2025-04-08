using ArgParse
using BBTournamentSim
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
            help = "Posterior probabilities parquet file"
            required = true
        "simulations"
            help = "Simulations parquet file"
            required = true
        "--expecto", "-e"
            help = "Path to output expected values file (CSV format)"
        "--exciteo", "-x"
            help = "Path to output expected values conditional on game winners file (Parquet format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    tournament = open(options["tournament"], "r") do io
        JSON3.read(io, BBTournamentSim.Tournament)
    end

    posteriors = DataFrame(Parquet2.readfile(options["posteriors"]))
    # parquet makes subsetting difficult
    transform!(posteriors, :owner => ByRow(String) => :owner)
    simulations = DataFrame(Parquet2.readfile(options["simulations"]))
    n_simulations = maximum(simulations[!, :simulation])

    # find games in the tournament that do not have winners but do have teams
    next_up = Vector{Int}()
    for game in 1:length(tournament)
        BBTournamentSim.is_done(tournament, game) && continue
        !BBTournamentSim.is_filled(tournament, game) && continue
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
        :rank => mean => :rank_mean,
        :rank => maximum => :rank_now,
        :rank => (x -> quantile(x, 0.75)) => :rank_q25,
        :rank => median => :rank_median,
        :rank => (x -> quantile(x, 0.25)) => :rank_q75,
        :rank => minimum => :rank_max,
        :rank => (x -> count(==(1), x) / n_simulations) => :p_win,
    )

    if !isnothing(options["expecto"])
        open(options["expecto"], "w") do io
            CSV.write(io, expecto)
        end
    else
        CSV.write(stdout, expecto)
    end

    subset!(simulations, :game => ByRow(in(next_up)))
    transform!(
        groupby(simulations, [:game, :winner]),
        nrow => :team_wins
    )
    subset!(posteriors, :rank => ByRow(==(1)))
    exciteo = combine(
        groupby(leftjoin(posteriors, simulations, on=:simulation), [:owner, :game, :winner, :team_wins]),
        nrow => :victories
    )
    transform!(exciteo, [:victories, :team_wins] => ByRow((v,w) -> v/w) => :conditional_p_win)

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