using ArgParse
using BBSim
using YAML

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "pickem"
            help = "Pick'Em picks data in CSV format"
            required = true
        "--teammap", "-m"
            help = "Team name mapping from Pick'Em to FiveThirtyEight in YAML format"
        "--picksfile", "-o"
            help = "Path to output picks file (in YAML format, default=STDOUT)"
        "--valuesfile", "-v"
            help = "Path to output values file (in YAML format, default=STDOUT)"
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

    pickem_options = PickEmSlateOptions()
    picks_data, vals = parse(pickem_options, options["pickem"])

    # Rename teams (inplace)
    for picks in values(picks_data)
        for i in eachindex(picks)
            picks[i] = get(team_map, picks[i], picks[i])
        end
    end

    if !isnothing(options["picksfile"])
        YAML.write_file(options["picksfile"], picks_data)
    else
        YAML.write(stdout, picks_data)
    end

    if !isnothing(options["valuesfile"])
        YAML.write_file(options["valuesfile"], vals)
    else
        YAML.write(stdout, vals)
    end
    
end

if !isinteractive()
    main()
end