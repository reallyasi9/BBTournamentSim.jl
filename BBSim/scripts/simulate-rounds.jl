using ArgParse
using BBSim
using JSON3

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    leagues = ("ncaam", "ncaaw")
    @add_arg_table! s begin
        "bracket"
            help = "Bracket definition JSON file"
        "teams"
            help = "Team ranking JSON file"
        "model"
            help = "Model definition JSON file"
        "--outfile", "-o"
            help = "Path to output round simulations (JSON format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    
end

if !isinteractive()
    main(ARGS)
end