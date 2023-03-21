using HTTP
using JSON3
using YAML
using URIs

const tournament_url_mens = "https://picks.cbssports.com/graphql?operationName=PoolSeasonStandingsQuery&variables=%7B%22skipAncestorPools%22%3Afalse%2C%22skipPeriodPoints%22%3Afalse%2C%22skipCheckForIncompleteEntries%22%3Atrue%2C%22gameInstanceUid%22%3A%22cbs-ncaab-tournament-manager%22%2C%22includedEntryIds%22%3A%5B%22ivxhi4tzhiytcnbxgqztsnzv%22%5D%2C%22poolId%22%3A%22kbxw63b2g4ztknztgi4a%3D%3D%3D%3D%22%2C%22first%22%3A50%2C%22orderBy%22%3A%22OVERALL_RANK%22%2C%22sortingOrder%22%3A%22ASC%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash%22%3A%22797a9386ad10d089d4d493a911bce5a63dae4efb4c02a0a32a40b20de37e002d%22%7D%7D"
const tournament_url_womens = "https://picks.cbssports.com/graphql?operationName=PoolSeasonStandingsQuery&variables=%7B%22skipAncestorPools%22%3Afalse%2C%22skipPeriodPoints%22%3Afalse%2C%22skipCheckForIncompleteEntries%22%3Atrue%2C%22gameInstanceUid%22%3A%22cbs-ncaaw-tournament-manager%22%2C%22includedEntryIds%22%3A%5B%22ivxhi4tzhiytgnrvgmytsnzu%22%5D%2C%22poolId%22%3A%22kbxw63b2ha4domzuha3q%3D%3D%3D%3D%22%2C%22first%22%3A50%2C%22orderBy%22%3A%22OVERALL_RANK%22%2C%22sortingOrder%22%3A%22ASC%22%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash%22%3A%22797a9386ad10d089d4d493a911bce5a63dae4efb4c02a0a32a40b20de37e002d%22%7D%7D"

const entry_query = "https://picks.cbssports.com/graphql?operationName=EntryDetailsQuery&extensions={%22persistedQuery%22%3A{%22version%22%3A1%2C%22sha256Hash%22%3A%22d2a67474fb3276c6f9f0b8d24eceda58de511926a9dadb7aa55f1065f67e6d85%22}}"

function get_entries(url)
    resp = HTTP.request("GET", url)
    json_resp = JSON3.read(resp.body)
    entries = json_resp["data"]["gameInstance"]["pool"]["entries"]["edges"]
    d = Dict(
        e["name"] => e["id"] for e in entries
    )
    return d
end

function get_bracket(query_url, entry_id)
    variables = URIs.escapeuri(JSON3.write(Dict("periodId" => "current", "entryId" => entry_id)))
    resp = HTTP.request("GET", query_url; query=["variables" => variables])
    json_resp = JSON3.read(resp.body)
    picks = [p["itemId"] for p in json_resp["data"]["entry"]["picks"]]
    return picks
end

function map_picks(team_map, picks)
    return [team_map[p] for p in picks]
end

if !isinteractive()
    w_team_map = YAML.load_file("cbs_teams_womens.yaml")
    w = get_entries(tournament_url_womens)
    w_picks = Dict{String,Vector{String}}()
    for (name, id) in w
        w_picks[name] = map_picks(w_team_map, get_bracket(entry_query, id))
    end
    YAML.write_file("cbs_picks_womens.yaml", w_picks)

    m_team_map = YAML.load_file("cbs_teams_mens.yaml")
    m = get_entries(tournament_url_mens)
    m_picks = Dict{String,Vector{String}}()
    for (name, id) in w
        m_picks[name] = map_picks(m_team_map, get_bracket(entry_query, id))
    end
    YAML.write_file("cbs_picks_mens.yaml", m_picks)
end

using HTTP
using JSON3
using YAML
using ArgParse

const query_url = "https://picks.cbssports.com/graphql"
const entries_operation_name = "PoolSeasonStandingsQuery"
const entry_operation_name = "EntryDetailsQuery"

const version = 1
const entries_query_hash = "797a9386ad10d089d4d493a911bce5a63dae4efb4c02a0a32a40b20de37e002d"
const entry_query_hash = "d2a67474fb3276c6f9f0b8d24eceda58de511926a9dadb7aa55f1065f67e6d85"

const default_pool_variables = Dict(
    "skipAncestorPools" => false,
    "skipPeriodPoints" => false,
    "skipCheckForIncompleteEntries" => true,
    "orderBy" => "OVERALL_RANK",
    "sortingOrder" => "ASC",
)

const game_instances = Dict("mens" => "cbs-ncaab-tournament-manager", "womens" => "cbs-ncaaw-tournament-manager")

#variables={,"gameInstanceUid":"cbs-ncaab-tournament-manager","poolId":"kbxw63b2g4ztknztgi4a====","first":50}
#extensions={"persistedQuery":{"version":1,"sha256Hash":"797a9386ad10d089d4d493a911bce5a63dae4efb4c02a0a32a40b20de37e002d"}}

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "cookie"
            help = "Authentication cookie information (scraped from CBS response data)"
        "gender"
            help = "Tournament gender to query (either 'mens' or 'womens')"
            range_tester = x -> x ∈ keys(game_instances)
        "poolid"
            help = "ID of pool"
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

function get_entiries_page(gender, pool_id, entries)
    variables = copy(default_pool_variables)
    variables["gameInstanceUid"] = game_instances[gender]
    variables["poolId"] = pool_id

    extensions = Dict(
        "persistedQuery" => Dict(
            "version" => version,
            "sha256Hash" => entries_query_hash,
        ),
    )
    
    for skip in 0:50:Integer(ceil(entries / 50)*50)
        # TODO: figure out skip
        variables["skip"] = skip
        query = Dict(
            "operationName" => operation_name,
            "variables" => JSON3.write(variables),
            "extensions" => JSON3.write(extensions),
        )

        resp = HTTP.request("GET", query_url; query=query)
    
        # TODO: append results
        json = JSON3.read(resp.body)
        json_teams = json["data"]["teams"]
        json_dict = Dict(
            t["id"] => t["location"] for t in json_teams
        )
        return json_dict
    end

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