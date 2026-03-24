using ArgParse
using BBTournamentSim
using JSON3
using URIs

const PATHS = Dict(
    "ncaam" => "/m-basket.htm",
    "ncaaw" => "/w-basket.htm",
)

const URL = "https://www.sonnymoorepowerratings.com"

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    leagues = ("ncaam", "ncaaw")
    @add_arg_table! s begin
        "old"
            help = "Past Moore file to update (JSON format)"
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

function (@main)(args)
    options = parse_arguments(args)

    league = options["league"]
    url = string(URIs.URI(URL; path=PATHS[league]))
    rpi_html = BBTournamentSim.get_moore(url)
    pairs = BBTournamentSim.parse_moore_html(rpi_html)
    teams = Dict{String, Float32}()
    for pair in pairs
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
