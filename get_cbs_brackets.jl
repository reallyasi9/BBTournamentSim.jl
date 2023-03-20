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