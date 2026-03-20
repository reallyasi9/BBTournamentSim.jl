using ArgParse
using BBTournamentSim
using JSON3
using URIs

const PATHS = Dict(
    "ncaam" => "/m-basket.htm",
    "ncaaw" => "/w-basket.htm",
)

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    leagues = ("ncaam", "ncaaw")
    @add_arg_table! s begin
        "--url"
            help = "Sonny Moore Ranking URL"
            default = "https://www.sonnymoorepowerratings.com"
        "league"
            required = true
            help = "League type (must be one of $(join(leagues, ", ", " or ")))"
            range_tester = in(leagues)
        "--outfile", "-o"
            help = "Path to output ratings file (YAML format)"
    end

    return parse_args(args, s)
end

function (@main)(args)
    options = parse_arguments(args)
    uri = URI(options["url"])
    uri_moore = URI(uri; path=PATHS[options["league"]])

    moore_html = BBTournamentSim.get_moore(string(uri_moore))
    pairs = BBTournamentSim.parse_moore_html(moore_html)
    teams = BBTournamentSim.Team[]
    for (i, pair) in enumerate(pairs)
        push!(teams, BBTournamentSim.Team(i, pair[1], options["league"], pair[2], nothing, nothing))
    end
    
    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, JSON3.write(teams))
        end
    else
        JSON3.pretty(JSON3.write(teams))
    end
end
