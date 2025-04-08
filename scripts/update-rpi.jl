using ArgParse
using BBTournamentSim
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
    rpi_html = BBTournamentSim.get_rpi(url)
    pairs = BBTournamentSim.parse_rpi_html(rpi_html)
    teams = Dict{String, Float32}()
    for (i,pair) in enumerate(pairs)
        teams[pair[1]] = pair[2]
    end

    old_teams = open(options["old"], "r") do io
        JSON3.read(io, Vector{BBTournamentSim.Team})
    end
    for i in eachindex(old_teams)
        old_team = old_teams[i]
        name = BBTournamentSim.name(old_team)
        rating = get(teams, name, BBTournamentSim.rating(old_team))
        old_teams[i] = BBTournamentSim.Team(BBTournamentSim.id(old_team), BBTournamentSim.name(old_team), BBTournamentSim.league(old_team), rating, BBTournamentSim.seed(old_team), BBTournamentSim.quadrant(old_team))
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