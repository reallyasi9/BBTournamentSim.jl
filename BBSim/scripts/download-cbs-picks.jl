using HTTP
using JSON3
using ArgParse

const query_url = "https://picks.cbssports.com/graphql"
const entries_operation_name = "PoolSeasonStandingsQuery"
const entry_operation_name = "EntryDetailsQuery"
const game_order_operation_name = "PoolPeriodQuery"

const version = 1
const entries_query_hash = "797a9386ad10d089d4d493a911bce5a63dae4efb4c02a0a32a40b20de37e002d"
const entry_query_hash = "20bc0168a6b1e097dec66495e6220abc3af4c3f81fd956566bbf71cb47acffd6"
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

const game_instances = Dict("ncaam" => "cbs-ncaab-tournament-manager", "ncaaw" => "cbs-ncaaw-tournament-manager")

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "pid"
            help = "Authentication PID cookie value (scraped from CBS response data)"
            required = true
        "poolid"
            help = "ID of pool"
            required = true
        "league"
            help = "Tournament league to query (either 'ncaam' or 'ncaaw')"
            range_tester = x -> x ∈ keys(game_instances)
            required = true
        "teammap"
            help = "Map of team IDs to team names in JSON format (use get-cbs-teams.jl to create)"
            required = true
        "teamseed"
            help = "Map to team names to seeds in JSON format (must be manually created)"
            required = true
        "--entries", "-n"
            help = "Maximum number of entries in pool (results are paginated in units of 50 entries)"
            arg_type = Int
            default = 50
        "--outfile", "-o"
            help = "Path to local output JSON file (default: STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function get_entiries_page(pid, league, pool_id, entries)
    cookies = Dict("pid" => pid)

    variables = copy(default_pool_variables)
    variables["gameInstanceUid"] = game_instances[league]
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
    collect(4:11),
    collect(34:41),
    collect(19:26),
    collect(49:56), # round 1

    collect(12:15),
    collect(42:45),
    collect(27:30),
    collect(57:60), # round 2

    collect(16:17),
    collect(46:47),
    collect(31:32),
    collect(61:62), # sweet sixteen

    [18, 48, 33, 63], # elite eight
    [64, 65], # final four
    [66], # championship
)

function get_game_order_page(pid, league, pool_id)
    cookies = Dict("pid" => pid)

    variables = copy(default_order_variables)
    variables["gameInstanceUid"] = game_instances[league]
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
        "entryId" => "ivxhi4tzhiytkobugy3domzx"
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

    team_map = open(options["teammap"], "r") do io
        JSON3.read(io)
    end

    team_seeds = open(options["teamseed"], "r") do io
        JSON3.read(io)
    end

    entries = get_entiries_page(options["pid"], options["league"], options["poolid"], options["entries"])
    order = get_game_order_page(options["pid"], options["league"], options["poolid"])
    
    # new format: vector of objects with "owner" and "picks" keys
    v = Vector{Dict{String, Any}}()
    for (key, val) in entries
        teams = get_bracket_page(options["pid"], val, team_map, order)
        teams = map(x -> team_seeds[x], teams)
        d = Dict("owner" => key, "picks" => teams)
        push!(v, d)
    end

    if isnothing(options["outfile"])
        JSON3.pretty(v)
    else
        open(options["outfile"], "w") do f
            JSON3.pretty(f, v)
        end
    end
end

if !isinteractive()
    main()
end