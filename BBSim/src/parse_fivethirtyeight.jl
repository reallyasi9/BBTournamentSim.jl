using CSV
using DataFrames
using Dates
using InlineStrings

function parse_fivethirtyeight(io::IO;
    gender = "mens",
    forecast_date::Union{Date,Symbol} = :latest,
    round_re = r"^rd(\d)_win$",
    team_name_remap = Dict{String,String}(),
)
    df = DataFrame(CSV.File(io))

    subset!(df, :gender => (g -> g .== gender))

    sort!(df, :forecast_date, rev=true)
    if forecast_date == :latest
        subset!(df, :forecast_date => (d -> d .== first(df[!, :forecast_date])))
    elseif type(forecast_date) == Symbol
        error("forecast_date must be a date or :latest")
    else
        idx = findfirst(x -> x < forecast_date, df[!, :forecast_date])
        dt = df[idx, :forecast_date]
        subset!(df, :forecast_date => (d -> d .== dt))
    end

    select!(df, :gender, :forecast_date, :team_name, round_re)
    stack_df = stack(df, round_re, [:gender, :forecast_date, :team_name], variable_name=:round, value_name=:win_probability)
    transform!(stack_df,
        :round => (r -> parse.(Int, replace.(r, round_re => s"\1")) .- 1), # round 1 is not meaningful to us
        :team_name => ByRow(n -> team_name_remap[n]),
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

function parse_fivethirtyeight(filename::AbstractString; kwargs...)
    return open(filename, "r") do io
        parse_fivethirtyeight(io; kwargs...)
    end
end