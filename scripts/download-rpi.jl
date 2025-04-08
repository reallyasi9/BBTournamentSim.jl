using ArgParse
using BBTournamentSim
using JSON3

const URLS = Dict("ncaaw" => "http://realtimerpi.com/ncaab/college_Women_basketball_power_rankings_Full.html", "ncaam" => "http://realtimerpi.com/ncaab/college_Men_basketball_power_rankings_Full.html")

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    leagues = ("ncaam", "ncaaw")
    @add_arg_table! s begin
        "league"
            help = "League type (must be one of $(join(leagues, ", ", " or ")))"
            range_tester = in(leagues)
            required = true
        "--outfile", "-o"
            help = "Path to output ratings file (JSON format)"
    end

    return parse_args(args, s)
end

function main(args=ARGS)
    options = parse_arguments(args)

    league = options["league"]
    url = URLS[league]
    rpi_html = BBTournamentSim.get_rpi(url)
    pairs = BBTournamentSim.parse_rpi_html(rpi_html)
    teams = BBTournamentSim.Team[]
    for (i,pair) in enumerate(pairs)
        push!(teams, BBTournamentSim.Team(i, pair[1], league, pair[2], nothing, nothing))
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