using HTTP
using JSON3
using ArgParse

const query_url = "https://picks.cbssports.com/graphql"
const operation_name = "CentralTeamsQuery"

const sports_types = Dict("ncaam" => "NCAAB", "ncaaw" => "NCAAW")
const version = 1
const query_hash = "0a75bf16d2074af6893f4386e7a17bed7f6fe04f96a00edfb75de3d5bdf527ba"

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "league"
            help = "Tournament league to query (either 'ncaam' or 'ncaaw')"
            range_tester = x -> x ∈ keys(sports_types)
            required = true
        "--outfile", "-o"
            help = "Path to local output JSON file (default: STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function get_team_page(league)
    variables = Dict(
        "sportTypes" => [sports_types[league]],
    )
    extensions = Dict(
        "persistedQuery" => Dict(
            "version" => version,
            "sha256Hash" => query_hash,
        ),
    )
    query = Dict(
        "operationName" => operation_name,
        "variables" => JSON3.write(variables),
        "extensions" => JSON3.write(extensions),
    )

    resp = HTTP.request("GET", query_url; query=query)
    
    json = JSON3.read(resp.body)
    json_teams = json["data"]["teams"]
    json_dict = Dict(
        t["id"] => t["location"] for t in json_teams
    )
    return json_dict
end

function main(args=ARGS)
    options = parse_arguments(args)
    d = get_team_page(options["league"])

    if isnothing(options["outfile"])
        JSON3.pretty(d)
    else
        open(options["outfile"], "w") do f
            JSON3.pretty(f, d)
        end
    end
end

if !isinteractive()
    main()
end