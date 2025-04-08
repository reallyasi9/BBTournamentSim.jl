using HTTP
using JSON3
using ArgParse

const query_url = "https://picks.cbssports.com/graphql"
const entries_operation_name = "PoolSeasonStandingsQuery"
const entry_operation_name = "EntryDetailsQuery"
const game_order_operation_name = "PoolPeriodQuery"

const version = 1
const entries_query_hash = "d4a5f361f30ebb86e3d9171ea21713de96057ad22dc12533d304fea89f8dea57"
const entry_query_hash = "720253f4494bde0f40858ce0819fcbd70a5beb7b3de55becb9d8bfd5976059be"
const game_order_query_hash = "bd4dd3122d072d332e7cd9143d0d29dcbde35798a79cea4703319efa42a95e04"

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

const start_game_per_round = [
    1, 33, 49, 57, 61, 63
]

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
            help = "Map of team IDs to team names in JSON format (use download-cbs-teams.jl to create)"
            required = true
        "teamseed"
            help = "Map to team names to seeds in JSON format (must be manually created with CBS team names as keys and seed numbers as values)"
            required = true
        "--outfile", "-o"
            help = "Path to local output JSON file (default: STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function get_entiries_page(pid, league, pool_id)
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

    variables["first"] = 50
    d = Dict{String, String}()

    while true

        query = Dict(
            "operationName" => entries_operation_name,
            "variables" => JSON3.write(variables),
            "extensions" => JSON3.write(extensions),
        )

        resp = HTTP.request("GET", query_url; query=query, cookies=cookies)

        json = JSON3.read(resp.body)
        es = json["data"]["gameInstance"]["pool"]["entries"]["edges"]
        
        if length(es) < 1
            break
        end

        merge!(d, Dict(
            e["node"]["name"] => e["node"]["id"] for e in es
        ))
        
        start = json["data"]["gameInstance"]["pool"]["entries"]["pageInfo"]["endCursor"]
        variables["after"] = start
    end

    return d
end

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
    # the matchup data tells me the ordinal position of the game
    ids = map(m -> m["id"], matchups)
    rounds = map(m -> m["tournamentRound"], matchups)
    ordinals = map(m -> m["roundOrdinal"], matchups)
    keepers = findall(rounds .> 1)

    rounds = rounds[keepers]
    ordinals = ordinals[keepers]
    game_numbers = ordinals .+ start_game_per_round[rounds .- 1]
    ids = ids[keepers]
    d = Dict(ids .=> game_numbers)
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

    entries = get_entiries_page(options["pid"], options["league"], options["poolid"])
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