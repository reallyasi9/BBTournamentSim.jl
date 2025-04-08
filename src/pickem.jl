using CSV
using DataFrames

Base.@kwdef struct PickEmSlateOptions
    game_column::Int = 1
    picker_columns::Vector{Int} = collect(2:41)
    points_column::Int = 44
    team_regex::Regex = r"^\s*\d+\s+(.*?)\s*$"
    game_regex::Regex = r"^Game(\d+)"
end

"""
    parse(options::PickEmSlateOptions, io)

Create picks from Pick'Em input.

The output is a `Dict{String, Vector{String31}}` and a `Vector{Float64}`.
In the `Dict`, the keys are picker's names and values are ordered lists of 63 team names corresponding to the picker's picks in each game.
The `Vector` is a list of point values of each game in bracket order.
Games technically have an arbitrary ordering: the ordering will be consistent between pickers and will match the order listed in the Pick'Em input.
The typical ordering is as follows:
- The first element represents the game between the #1 and #16 seeds in quadrant 1 of the bracket;
- the second element represents the game between the #8 and #9 seeds in quadrant 1, and so on; until
- the 32nd element represents the game between the #2 and #15 seeds  in quadrant 4; 
- the 33rd element represents the game between the winner of games 1 and 2;
- the 34th element represents the game between the winner of games 3 and 4, and so on; until
- the 61st element represents the Final Four matchup between quadrants 1 and 2;
- the 62nd element represents the Final Four matchup between quadrants 3 and 4; and
- the 63rd element represents the championship game.
"""
function Base.parse(options::PickEmSlateOptions, io::IO)

    # To be filled in during the loop over CSV rows
    df = DataFrame()

    # To be incremented as necessary
    round = 0

    # Unknown to start
    pickers = Symbol[]

    rows = CSV.Rows(io;
        select = vcat([options.game_column], options.picker_columns, [options.points_column])
    )
    for row in rows
        # For display reasons, some rows are entirely empty
        if ismissing(row[options.game_column])
            continue
        end

        matches = match(options.game_regex, row[options.game_column])
        # A non-empty row that doesn't start with something that looks like a game identifier
        # is a round identifier instead.
        if isnothing(matches)
            round += 1
            continue
        end

        game_number = parse(Int, matches.captures[1])

        # Lazily fill in the pickers, but only with pickers that picked the first game
        if isempty(pickers)
            pickers = filter(n -> !ismissing(row[n]), rows.names[options.picker_columns])
        end

        for picker in pickers
            pick_match = match(options.team_regex, row[picker])
            if isnothing(pick_match)
                error("unable to match picked team for picker '$picker' in string '$(row[picker])'")
            end
            pick = pick_match.captures[1]

            # The points row was the last row selected when constructing the CSV.Rows object
            points = parse(Float64, last(row))

            entry = (
                picker = string(picker),
                round = round,
                game = game_number,
                pick = pick,
                value = points,
            )
            push!(df, entry)
        end
    end

    # Each picker ought to have the same values for each pick. If not, something is amiss
    # (maybe we are using upset scoring?)
    game_groups = groupby(df, [:game, :value])
    if length(game_groups) != length(unique(df[!, :game]))
        error("each game must have the same value across all pickers")
    end
    values = combine(game_groups, :value => first => :value)[!, :value]
    
    picker_groups = groupby(df, :picker)
    picks = Dict(getindex.(keys(picker_groups), 1) .=> [g.pick for g in picker_groups])
    return picks, values
end

function Base.parse(options::PickEmSlateOptions, filename::AbstractString)
    return open(filename, "r") do io
        parse(options, io)
    end
end