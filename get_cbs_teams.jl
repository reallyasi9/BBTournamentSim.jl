using HTTP
using JSON3
using YAML

const team_db_url_mens = "https://picks.cbssports.com/graphql?operationName=CentralTeamsQuery&variables={%22sportTypes%22:[%22NCAAB%22],%22subsection%22:null}&extensions={%22persistedQuery%22:{%22version%22:1,%22sha256Hash%22:%220a75bf16d2074af6893f4386e7a17bed7f6fe04f96a00edfb75de3d5bdf527ba%22}}"
const team_db_url_womens = "https://picks.cbssports.com/graphql?operationName=CentralTeamsQuery&variables={%22sportTypes%22:[%22NCAAW%22],%22subsection%22:null}&extensions={%22persistedQuery%22:{%22version%22:1,%22sha256Hash%22:%220a75bf16d2074af6893f4386e7a17bed7f6fe04f96a00edfb75de3d5bdf527ba%22}}"

function get_team_page(uri)
    resp = HTTP.request("GET", uri)
    json = JSON3.read(resp.body)
    json_teams = json["data"]["teams"]
    json_dict = Dict(
        t["id"] => t["location"] for t in json_teams
    )
    return json_dict
end

if !isinteractive()
    w = get_team_page(team_db_url_womens)
    YAML.write_file("cbs_teams_womens.yaml", w)
    m = get_team_page(team_db_url_mens)
    YAML.write_file("cbs_teams_mens.yaml", m)
end