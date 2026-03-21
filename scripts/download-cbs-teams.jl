using HTTP
using JSON3
using ArgParse
using Base64

const QUERY_URLS = Dict(
    "ncaam" => "https://www.cbssports.com/college-basketball/ncaa-tournament/bracket/",
    "ncaaw" => "https://www.cbssports.com/womens-college-basketball/ncaa-tournament/bracket/",
)

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "league"
            help = "Tournament league to query (either 'ncaam' or 'ncaaw')"
            range_tester = x -> x ∈ keys(QUERY_URLS)
            required = true
        "--outfile", "-o"
            help = "Path to local output JSON file (default: STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function get_team_page(league)
    query_url = QUERY_URLS[league]
    resp = HTTP.request("GET", query_url)
    return String(resp.body)
end

function parse_team_page(html)
    regex = r"define\('reduxPreloadedState', \[\], function\(\) {.*?atob\('(.*?)'"ms
    matches = match(regex, html)
    if isnothing(matches)
        throw(ErrorException("unable to parse preloaded state information from HTML"))
    end

    decoded = base64decode(matches.captures[1])
    json = JSON3.read(decoded)
    json_teams = json["bracket"]["data"][1]["picksTeams"]
    json_dict = Dict(
        t["id"] => t["location"] for t in values(json_teams)
    )
    return json_dict
end

function (@main)(args)
    options = parse_arguments(args)
    html = get_team_page(options["league"])
    d = parse_team_page(html)

    if isnothing(options["outfile"])
        JSON3.pretty(d)
    else
        open(options["outfile"], "w") do f
            JSON3.pretty(f, d)
        end
    end
end
