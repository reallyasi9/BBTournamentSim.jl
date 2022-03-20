using JSON3
using YAML

teammapfile = JSON3.read(read("cbs-teammap-2022m.json"))
teamlookup = YAML.load_file("team-lookup.yaml")

teammap = Dict(t.id => get(teamlookup, t.shortName, missing) for t in teammapfile.data.teams)

const slotorder = Dict("jvqxiy3iovydunbuha======" => 35, "jvqxiy3iovydunbuga======" => 27, "jvqxiy3iovydunbvgm======" => 40, "jvqxiy3iovydunbvgi======" => 39, "jvqxiy3iovydunbsgi======" => 9, "jvqxiy3iovydunbthe======" => 26, "jvqxiy3iovydunbrgy======" => 3, "jvqxiy3iovydunbtha======" => 25, "jvqxiy3iovydunbsga======" => 7, "jvqxiy3iovydunbwgy======" => 53, "jvqxiy3iovydunbsge======" => 8, "jvqxiy3iovydunbvgy======" => 43, "jvqxiy3iovydunbrha======" => 5, "jvqxiy3iovydunbwg4======" => 54, "jvqxiy3iovydunbuge======" => 28, "jvqxiy3iovydunbtgy======" => 23, "jvqxiy3iovydunbsha======" => 15, "jvqxiy3iovydunbvgq======" => 41, "jvqxiy3iovydunbwha======" => 55, "jvqxiy3iovydunbrgu======" => 2, "jvqxiy3iovydunbxgi======" => 59, "jvqxiy3iovydunbshe======" => 16, "jvqxiy3iovydunbsgy======" => 13, "jvqxiy3iovydunbwgm======" => 50, "jvqxiy3iovydunbugu======" => 32, "jvqxiy3iovydunbugq======" => 31, "jvqxiy3iovydunbugm======" => 30, "jvqxiy3iovydunbvha======" => 45, "jvqxiy3iovydunbwhe======" => 56, "jvqxiy3iovydunbvge======" => 38, "jvqxiy3iovydunbugi======" => 29, "jvqxiy3iovydunbwgq======" => 51, "jvqxiy3iovydunbugy======" => 33, "jvqxiy3iovydunbxgm======" => 60, "jvqxiy3iovydunbwgi======" => 49, "jvqxiy3iovydunbvg4======" => 44, "jvqxiy3iovydunbtge======" => 18, "jvqxiy3iovydunbvga======" => 37, "jvqxiy3iovydunbxgy======" => 63, "jvqxiy3iovydunbwga======" => 47, "jvqxiy3iovydunbxgu======" => 62, "jvqxiy3iovydunbsgu======" => 12, "jvqxiy3iovydunbrhe======" => 6, "jvqxiy3iovydunbrg4======" => 4, "jvqxiy3iovydunbsg4======" => 14, "jvqxiy3iovydunbug4======" => 34, "jvqxiy3iovydunbtgq======" => 21, "jvqxiy3iovydunbrgq======" => 1, "jvqxiy3iovydunbwge======" => 48, "jvqxiy3iovydunbvgu======" => 42, "jvqxiy3iovydunbxge======" => 58, "jvqxiy3iovydunbtgu======" => 22, "jvqxiy3iovydunbtgi======" => 19, "jvqxiy3iovydunbxga======" => 57, "jvqxiy3iovydunbsgq======" => 11, "jvqxiy3iovydunbtgm======" => 20, "jvqxiy3iovydunbuhe======" => 36, "jvqxiy3iovydunbtga======" => 17, "jvqxiy3iovydunbxgq======" => 61, "jvqxiy3iovydunbtg4======" => 24, "jvqxiy3iovydunbsgm======" => 10, "jvqxiy3iovydunbwgu======" => 52, "jvqxiy3iovydunbvhe======" => 46)

const values = vcat(
    repeat([1], 32),
    repeat([2], 16),
    repeat([4], 8),
    repeat([8], 4),
    repeat([16], 2),
    repeat([32], 1),
)

output = Dict{String, Dict{String,Vector{Int}}}()
for fn in ARGS
    pickfile = JSON3.read(read(fn))
    if :data ∉ keys(pickfile)
        @warn "data not found in pickfile" fn
        continue
    end
    if length(pickfile.data.entry.picks) != 63
        @warn "pickfile does not contain a complete set of picks" fn npicks=length(pickfile.data.entry.picks)
        continue
    end
    name = pickfile.data.entry.name
    picks = zeros(63)
    for p in pickfile.data.entry.picks
        n = slotorder[p.slotId]
        picks[n] = teammap[p.itemId]
    end
    if isempty(picks)
        @warn "no picks in pickfile" fn name
        continue
    end
    output[name] = Dict("winners"=>picks, "points"=>values)
end

println(YAML.write(output))
