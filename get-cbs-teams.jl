using HTTP
using JSON3
using YAML
using ArgParse

const query_url = "https://picks.cbssports.com/graphql"
const operation_name = "CentralTeamsQuery"

const sports_types = Dict("mens" => "NCAAB", "womens" => "NCAAW")
const version = 1
const query_hash = "0a75bf16d2074af6893f4386e7a17bed7f6fe04f96a00edfb75de3d5bdf527ba"

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "gender"
            help = "Tournament gender to query (either 'mens' or 'womens')"
            range_tester = x -> x ∈ keys(sports_types)
            required = true
        "--outfile", "-o"
            help = "Path to local output YAML file (default: STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function get_team_page(gender)
    variables = Dict(
        "sportTypes" => [sports_types[gender]],
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
    d = get_team_page(options["gender"])

    if isnothing(options["outfile"])
        YAML.write(stdout, d)
    else
        YAML.write_file(options["outfile"], d)
    end
end

if !isinteractive()
    main()
end