using CSV
using DataFrames
using Dates
using InlineStrings

Base.@kwdef struct FiveThirtyEightPredictionOptions
    gender::String = "mens"
    forecast_date::Union{Date,Symbol} = :latest
    round_regex::Regex = r"^rd(\d)_win$"
    team_name_map::Dict{String,String}
end

"""
    parse(options::FiveThirtyEightPredictionOptions, io)

Create a prediction table from input.

The output is a `Dict{Pair{String31, Int}, Float64}` where the keys are pairs of `team => round` and the values are the predicted probability of that `team` winning the game in that `round`.
The `round` values range from 1 to 6, with 1 being the round of 64 (opening round, excluding the 4 play-in games) and 6 being the championship game.
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
    stack_df = stack(df, round_re, [:gender, :forecast_date, :team_name], variable_name=:round, value_name=:win_probability)
    transform!(stack_df,
        :round => (r -> parse.(Int, replace.(r, round_re => s"\1")) .- 1), # round 1 is not meaningful to us
        :team_name => ByRow(n -> get(options.team_name_map, n, n)),
        renamecols = false)
    
    # some team names are shared because Pick'Em does not differentiate between play-in teams
    merged_df = combine(
        groupby(stack_df, Not(:win_probability)),
        :win_probability => p -> maximum(p),
        renamecols = false,
    )

    # turn into a probability table, indexed by team => round
    probability_table = Dict{Pair{String31, Int}, Float64}()
    for row in copy.(eachrow(select(merged_df, :team_name, :round, :win_probability)))
        probability_table[String31(row.team_name) => row.round] = row.win_probability
    end

    return probability_table

end

function Base.parse(options::FiveThirtyEightPredictionOptions, filename::AbstractString)
    return open(filename, "r") do io
        parse(options, io)
    end
end