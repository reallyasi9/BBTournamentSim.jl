using HTTP
using JSON3
using ArgParse

const game_order_urls = Dict(
    # add the pool ID at the end
    "ncaam" => "https://picks.cbssports.com/college-basketball/ncaa-tournament/bracket/pools/",
    "ncaaw" => "https://picks.cbssports.com/college-basketball/ncaaw-tournament/bracket/pools/",
)

const query_url = "https://picks.cbssports.com/graphql"
const entries_operation_name = "BracketManagerPoolStandings"
const entry_operation_name = "NCAABracketManagerBracketPage"

const version = 1
const entries_query_hash = "5db99329692b412a8873d5f382b376d2c97178d1e12bcfb7ea53faa2113b05cb"
const entry_query_hash = "212108863b3d694b6b91b433026f02183fd4478545b11ce695149091866f8539"

const default_pool_variables = Dict{String, Any}(
    "displayingArchivedPool" => false,
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

function get_entries_page(pid, league, pool_id)
    cookies = Dict("pid" => pid)

    variables = copy(default_pool_variables)
    variables["poolId"] = pool_id

    extensions = Dict(
        "persistedQuery" => Dict(
            "version" => version,
            "sha256Hash" => entries_query_hash,
        ),
    )

    variables["first"] = 100
    d = Dict{String, String}()

    while true

        query = Dict(
            "operationName" => entries_operation_name,
            "variables" => JSON3.write(variables),
            "extensions" => JSON3.write(extensions),
        )

        resp = HTTP.request("GET", query_url; query=query, cookies=cookies)

        json = JSON3.read(resp.body)
        es = json["data"]["commonPool"]["standings"]["edges"]
        
        if length(es) < 1
            break
        end

        merge!(d, Dict(
            e["node"]["name"] => e["node"]["id"] for e in es
        ))
        
        has_next = json["data"]["commonPool"]["standings"]["pageInfo"]["hasNextPage"]
        if !has_next
            break
        end
        start = json["data"]["commonPool"]["standings"]["pageInfo"]["endCursor"]
        variables["after"] = start
    end

    return d
end

function get_game_order_page(pid, league, pool_id)
    cookies = Dict("pid" => pid)

    query_url = game_order_urls[league] * pool_id
    resp = HTTP.request("GET", query_url; cookies=cookies)
    html = String(resp.body)

    # replace undefineds with nulls
    html = replace(html, "undefined"=>"null")

    regex = r"window\[Symbol\.for\(\"ApolloSSRDataTransport\"\)\] \?\?= \[\]\)\.push\((\{.*?\})\)<"ms
    matches = match(regex, html)
    if isnothing(matches)
        throw(ErrorException("unable to parse hydration data"))
    end
    json_str = matches.captures[1]
    json = JSON3.read(json_str)
    rehydrate = json["rehydrate"]
    # rehydrate element has random keys
    key = only(filter(k -> "data" ∈ keys(rehydrate[k]) && !isnothing(rehydrate[k]["data"]) && "ncaaBasketballTournamentMatchups" ∈ keys(rehydrate[k]["data"]), keys(rehydrate)))

    matchups = rehydrate[key]["data"]["ncaaBasketballTournamentMatchups"]
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
        "productAbbrev" => "bpc", # ?
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
    json_picks = json["data"]["commonEntry"]["picks"]
    picks = String[]
    permutation = Int[]
    for (i, p) in enumerate(json_picks)
        if "team" ∉ keys(p)
            throw(ErrorException("no team picked for game $i in entry $entry_id"))
        end
        team = p["team"]
        if "cbsTeamId" ∉ keys(team)
            throw(ErrorException("no cbsTeamId for team picked in game $i in entry $entry_id"))
        end
        team_id = string(team["cbsTeamId"])
        push!(picks, team_map[team_id])

        if "slotId" ∉ keys(p)
            throw(ErrorException("no slotId for game $i in entry $entry_id"))
        end
        slot_id = p["slotId"]
        if slot_id ∉ keys(order)
            throw(ErrorException("slotId $slot_id not known in tournament order"))
        end
        push!(permutation, order[slot_id])
    end

    invpermute!(picks, permutation)

    return picks

end

function (@main)(args)
    options = parse_arguments(args)

    team_map = open(options["teammap"], "r") do io
        JSON3.read(io, Dict{String,String})
    end

    team_seeds = open(options["teamseed"], "r") do io
        JSON3.read(io, Dict{String,String})
    end

    entries = get_entries_page(options["pid"], options["league"], options["poolid"])
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
