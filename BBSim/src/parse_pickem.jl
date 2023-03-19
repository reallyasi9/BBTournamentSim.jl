using CSV
using DataFrames

function parse_pickem(io::IO;
    game_col = 1,
    picker_cols = collect(2:41),
    points_col = 44,
    team_re = r"^\s*\d+\s+(.*?)\s*$",
    game_re = r"^Game(\d+)",
)
    df = DataFrame()
    round = 0
    pickers = Symbol[]
    rows = CSV.Rows(io; select = vcat([game_col], picker_cols, [points_col]))
    for row in rows
        if ismissing(row[game_col])
            continue
        end
        matches = match(game_re, row[game_col])
        if isnothing(matches)
            round += 1
            continue
        end
        game_number = parse(Int, matches.captures[1])
        if isempty(pickers)
            pickers = filter(n -> !ismissing(row[n]), rows.names[picker_cols])
        end
        for picker in pickers
            pick_match = match(team_re, row[picker])
            if isnothing(pick_match)
                error("unable to match picked team for picker '$picker' in string '$(row[picker])'")
            end
            pick = pick_match.captures[1]
            points = parse(Float64, last(row))
            entry = (picker = string(picker), round = round, game = game_number, pick = pick, value = points)
            push!(df, entry)
        end
    end
    values = combine(groupby(df, :game), :value => maximum => :value)[!, :value]
    picker_groups = groupby(df, :picker)
    picks = Dict(getindex.(keys(picker_groups), 1) .=> [g.pick for g in picker_groups])
    return picks, values
end

function parse_pickem(filename::AbstractString; kwargs...)
    return open(filename, "r") do io
        parse_pickem(io; kwargs...)
    end
end