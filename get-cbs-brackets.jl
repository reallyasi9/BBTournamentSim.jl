using HTTP
using JSON3
using YAML
using ArgParse

const query_url = "https://picks.cbssports.com/graphql"
const entries_operation_name = "PoolSeasonStandingsQuery"
const entry_operation_name = "EntryDetailsQuery"
const game_order_operation_name = "PoolPeriodQuery"

const version = 1
const entries_query_hash = "797a9386ad10d089d4d493a911bce5a63dae4efb4c02a0a32a40b20de37e002d"
const entry_query_hash = "d2a67474fb3276c6f9f0b8d24eceda58de511926a9dadb7aa55f1065f67e6d85"
const game_order_query_hash = "1f7753b6edfd22c41fb1d59e2850260f008782ffd8d5606a91837dbb78e54cb3"

const default_pool_variables = Dict(
    "skipAncestorPools" => false,
    "skipPeriodPoints" => false,
    "skipCheckForIncompleteEntries" => true,
    "orderBy" => "OVERALL_RANK",
    "sortingOrder" => "ASC",
)

const default_order_variables = Dict(
    "isBracket" => true,
    "periodId" => "current",
    "includeEvents" => false,
)

const game_instances = Dict("mens" => "cbs-ncaab-tournament-manager", "womens" => "cbs-ncaaw-tournament-manager")

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "pid"
            help = "Authentication PID cookie value (scraped from CBS response data)"
            required = true
        "poolid"
            help = "ID of pool"
            required = true
        "gender"
            help = "Tournament gender to query (either 'mens' or 'womens')"
            range_tester = x -> x ∈ keys(game_instances)
            required = true
        "teammap"
            help = "Map of team IDs to team names in YAML format (use get-cbs-teams.jl to create)"
            required = true
        "--entries", "-n"
            help = "Maximum number of entries in pool (results are paginated in units of 50 entries)"
            arg_type = Int
            default = 50
        "--outfile", "-o"
            help = "Path to local output YAML file (default: STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function get_entiries_page(pid, gender, pool_id, entries)
    cookies = Dict("pid" => pid)

    variables = copy(default_pool_variables)
    variables["gameInstanceUid"] = game_instances[gender]
    variables["poolId"] = pool_id

    extensions = Dict(
        "persistedQuery" => Dict(
            "version" => version,
            "sha256Hash" => entries_query_hash,
        ),
    )
    
    # for skip in 0:50:Integer(ceil((entries-1) / 50)*50)
    # TODO: figure out skip
    # variables["skip"] = skip
    variables["first"] = 50 # FIXME
    query = Dict(
        "operationName" => entries_operation_name,
        "variables" => JSON3.write(variables),
        "extensions" => JSON3.write(extensions),
    )

    resp = HTTP.request("GET", query_url; query=query, cookies=cookies)

    # TODO: append results
    json = JSON3.read(resp.body)
    entries = json["data"]["gameInstance"]["pool"]["entries"]["edges"]
    d = Dict(
        e["node"]["name"] => e["node"]["id"] for e in entries
    )
    # end

    return d
end

const matchup_order = vcat(
    collect(0:7),
    collect(30:37),
    collect(15:22),
    collect(45:52), # round 1

    collect(8:11),
    collect(38:41),
    collect(23:26),
    collect(53:56), # round 2

    collect(12:13),
    collect(42:43),
    collect(27:28),
    collect(57:58), # sweet sixteen

    [14, 44, 29, 59], # elite eight
    [60, 61], # final four
    [62], # championship
)

function get_game_order_page(pid, gender, pool_id)
    cookies = Dict("pid" => pid)

    variables = copy(default_order_variables)
    variables["gameInstanceUid"] = game_instances[gender]
    variables["poolId"] = pool_id

    extensions = Dict(
        "persistedQuery" => Dict(
            "version" => version,
            "sha256Hash" => game_order_query_hash,
        ),
    )
    
    query = Dict(
        "operationName" => game_order_operation_name,
        "variables" => JSON3.write(variables),
        "extensions" => JSON3.write(extensions),
    )

    resp = HTTP.request("GET", query_url; query=query, cookies=cookies)
    json = JSON3.read(resp.body)

    matchups = json["data"]["gameInstance"]["period"]["matchups"]
    d = Dict(matchups[matchup_order[i]+1]["id"] => i for i in eachindex(matchup_order))
    return d
end

function get_bracket_page(pid, entry_id, team_map, order)
    cookies = Dict("pid" => pid)

    variables = Dict(
        "periodId" => "current",
        "entryId" => entry_id
    )

    extensions = Dict(
        "persistedQuery" => Dict(
            "version" => version,
            "sha256Hash" => entry_query_hash,
        ),
    )
    
    query = Dict(
        "operationName" => entry_operation_name,
        "variables" => JSON3.write(variables),
        "extensions" => JSON3.write(extensions),
    )

    resp = HTTP.request("GET", query_url; query=query, cookies=cookies)

    json = JSON3.read(resp.body)
    json_picks = json["data"]["entry"]["picks"]
    picks = [team_map[p["itemId"]] for p in json_picks]

    permutation = [order[p["slotId"]] for p in json_picks]
    invpermute!(picks, permutation)

    return picks

end

function main(args=ARGS)
    options = parse_arguments(args)

    team_map = YAML.load_file(options["teammap"])

    entries = get_entiries_page(options["pid"], options["gender"], options["poolid"], options["entries"])
    order = get_game_order_page(options["pid"], options["gender"], options["poolid"])
    d = Dict(key => get_bracket_page(options["pid"], val, team_map, order) for (key, val) in entries)

    if isnothing(options["outfile"])
        YAML.write(stdout, d)
    else
        YAML.write_file(options["outfile"], d)
    end
end

if !isinteractive()
    main()
end