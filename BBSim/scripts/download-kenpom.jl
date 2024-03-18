using ArgParse
using BBSim
using JSON3


function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--url"
            help = "Kenpom URL"
            default = "https://kenpom.com"
        "--outfile", "-o"
            help = "Path to output ratings file (YAML format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    kenpom_html = BBSim.get_kenpom(options["url"])
    pairs = BBSim.parse_kenpom_html(kenpom_html)
    teams = BBSim.Team[]
    for pair in pairs
        push!(teams, BBSim.Team(pair[1], pair[2], nothing, nothing))
    end
    
    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, JSON3.write(teams))
        end
    else
        JSON3.pretty(JSON3.write(teams))
    end
end

if !isinteractive()
    main(ARGS)
end