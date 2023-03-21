using ArgParse
using BBSim
using YAML

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "fivethirtyeight"
            help = "FiveThirtyEight probability data in CSV format"
            required = true
        "gender"
            help = "Bracket gender ('mens' or 'womens')"
            required = true
        "--combine", "-c"
            help = "Path to file containing combined team renamings (YAML format)"
        "--outfile", "-o"
            help = "Path to output probability table (YAML format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    if !isnothing(options["combine"])
        combine = YAML.load_file(options["combine"])
    else
        combine = Dict{String, String}()
    end

    fte_options = FiveThirtyEightPredictionOptions(gender=options["gender"], combine_teams=combine)
    fte_data = parse(fte_options, options["fivethirtyeight"])

    if !isnothing(options["outfile"])
        YAML.write_file(options["outfile"], fte_data)
    else
        YAML.write(stdout, fte_data)
    end
end

if !isinteractive()
    main()
end