using CSV
using DataFrames
using Dates

Base.@kwdef struct FiveThirtyEightPredictionOptions
    gender::String = "mens"
    forecast_date::Union{Date,Symbol} = :latest
    round_regex::Regex = r"^rd(\d)_win$"
    combine_teams::Dict{String, String}
end

"""
    parse(options::FiveThirtyEightPredictionOptions, io)

Create a prediction table from input.

The output is a `Dict{String, Vector{Float64}}` where the keys are team names and the values are the probability of that team winning the given round, indexed by round number.
Rounds start from 1 (round of 64, skipping the play-in games) go to 6 (championship game).
"""
function Base.parse(options::FiveThirtyEightPredictionOptions, io::IO)
    df = DataFrame(CSV.File(io))

    subset!(df, :gender => (g -> g .== options.gender))

    sort!(df, :forecast_date, rev=true)
    if options.forecast_date == :latest
        subset!(df, :forecast_date => (d -> d .== first(df[!, :forecast_date])))
    elseif type(options.forecast_date) == Symbol
        error("forecast_date must be a date or :latest")
    else
        idx = findfirst(x -> x < options.forecast_date, df[!, :forecast_date])
        dt = df[idx, :forecast_date]
        subset!(df, :forecast_date => (d -> d .== dt))
    end

    select!(df, :gender, :forecast_date, :team_name, options.round_regex)
    stack_df = stack(df, options.round_regex, [:gender, :forecast_date, :team_name], variable_name=:round, value_name=:win_probability)
    transform!(stack_df,
        :round => (r -> parse.(Int, replace.(r, options.round_regex => s"\1")) .- 1), # round 1 is not meaningful to us
        renamecols = false)
    subset!(stack_df, :round => (r -> r .!= 0))

    # turn into a probability table, indexed by team, then round
    probability_table = Dict{String, Vector{Float64}}()
    for row in copy.(eachrow(select(stack_df, :team_name, :round, :win_probability)))
        # combine team probabilities, taking the maximum of the two
        team_name = get(options.combine_teams, row.team_name, row.team_name)
        v = get!(probability_table, team_name, zeros(Float64, 6))
        v[row.round] = max(row.win_probability, v[row.round])
    end

    return probability_table

end

function Base.parse(options::FiveThirtyEightPredictionOptions, filename::AbstractString)
    return open(filename, "r") do io
        parse(options, io)
    end
end