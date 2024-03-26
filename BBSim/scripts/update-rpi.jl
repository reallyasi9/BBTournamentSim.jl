using ArgParse
using BBSim
using JSON3

const URLS = Dict("ncaaw" => "http://realtimerpi.com/ncaab/college_Women_basketball_power_rankings_Full.html", "ncaam" => "http://realtimerpi.com/ncaab/college_Men_basketball_power_rankings_Full.html")

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    leagues = ("ncaam", "ncaaw")
    @add_arg_table! s begin
        "old"
            help = "Past RPI file to update (JSON format)"
            required = true
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
    rpi_html = BBSim.get_rpi(url)
    pairs = BBSim.parse_rpi_html(rpi_html)
    teams = Dict{String, Float32}()
    for (i,pair) in enumerate(pairs)
        teams[pair[1]] = pair[2]
    end

    old_teams = open(options["old"], "r") do io
        JSON3.read(io, Vector{BBSim.Team})
    end
    for i in eachindex(old_teams)
        old_team = old_teams[i]
        name = BBSim.name(old_team)
        rating = get(teams, name, BBSim.rating(old_team))
        old_teams[i] = BBSim.Team(BBSim.id(old_team), BBSim.name(old_team), BBSim.league(old_team), rating, BBSim.seed(old_team), BBSim.quadrant(old_team))
    end
    
    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, old_teams)
        end
    else
        JSON3.pretty(old_teams)
    end
end

if !isinteractive()
    main(ARGS)
end