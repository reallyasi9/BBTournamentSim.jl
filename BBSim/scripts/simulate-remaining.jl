using ArgParse
using BBSim
using JSON3
using Random
using Parquet2

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "tournament"
            help = "Current tournament status JSON file"
            required = true
        "model"
            help = "Model definition JSON file"
            required = true
        "--simulations", "-n"
            help = "Number of simulations to run"
            arg_type = Int
            default = 1000
        "--seed", "-s"
            help = "Random number generator seed"
            arg_type = Int
        "--outfile", "-o"
            help = "Path to output round simulations (Parquet format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    rng = isnothing(options["seed"]) ? Random.GLOBAL_RNG : Random.Xoshiro(options["seed"])

    tournament = open(options["tournament"], "r") do io
        JSON3.read(io, BBSim.Tournament)
    end

    model = open(options["model"], "r") do io
        JSON3.read(io, BBSim.AbstractModel)
    end

    nsim = options["simulations"]
    simulated_winners = BBSim.simulate(rng, model, tournament, nsim)
    
    if !isnothing(options["outfile"])
        # stored as nsim (second dim) columns of winners (first dim) in tournament order
        games = repeat(collect(1:length(tournament)), nsim)
        # cheat
        sims = sort!(repeat(collect(1:nsim), length(tournament)))
        data = (simulation=sims, game=games, winner=simulated_winners[:])

        open(options["outfile"], "w") do f
            Parquet2.writefile(f, data)
        end
    else
        display(size(simulated_winners))
    end
end

if !isinteractive()
    main(ARGS)
    # main(split(raw"../tournament_ncaaw_2024_20240318.json ../model_2024.json -s 42 -o ../test.parquet", " "))
end 