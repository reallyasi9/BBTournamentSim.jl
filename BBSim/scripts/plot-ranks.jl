using CairoMakie
using ArgParse
using Parquet2
using Tables

# input is a table with columns (simulation, owner, points, rank)
# we need to convert this to a Dict of (picker => [probs]) where [probs] are the probabilities of the picker achieving each rank (first element is rank 1, etc.)
function rank_table_to_dict(table)
    owners = unique(Tables.getcolumn(table, :owner))
    n_pickers = length(owners)
    n_sims = maximum(Tables.getcolumn(table, :simulation))
    values = Dict(owner => zeros(n_pickers) for owner in owners)
    for (owner, rank) in zip(Tables.getcolumn(table, :owner), Tables.getcolumn(table, :rank))
        values[owner][rank] += 1
    end
    return Dict(owner => values[owner] / n_sims for owner in keys(values))
end

function ordinal_rank(values)
    map(values) do v
        n = Int(v)
        (n ÷ 10) % 10 == 1 && return "$(n)th"
        last = n % 10
        last == 1 && return "$(n)st"
        last == 2 && return "$(n)nd"
        last == 3 && return "$(n)rd"
        return "$(n)th"
    end
end

"""
    plot_ranks(ranks)

`ranks` is a dict with picker names as keys and a vector of probabilites of ranks (the nth index corresponding to probability of coming in nth place).
"""
function plot_ranks(ranks)
    n_ranks = length(ranks)
    fig = Figure(;
        size = (54 * n_ranks, 200 * n_ranks),
        fonts = (;regular = "DejaVu Sans"),
    )
    names = sort(collect(keys(ranks)))

    xs = collect(1:n_ranks)
    for (i,name) in enumerate(names)
        ax = Axis(fig[i,1];
            title=name,
            titlealign=:left,
            titlesize=24,
            xticks=1:length(ranks),
            xtickformat = ordinal_rank,
        )
        ys = ranks[name]
        max_y = maximum(ys)
        barplot!(ax, 
            xs,
            ys,
            bar_labels = :y, 
            label_formatter = x -> string(Int(round(x*100))) * "%", 
            label_size = 16,
            strokewidth = 0.5, 
            strokecolor = :black,
            flip_labels_at = max_y * .80,
            color_over_background = :black,
            color_over_bar = :white,
        )
    end

    return fig
end

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "posteriors"
            help = "Posterior draws in Parquet format"
            required = true
        "--outfile", "-o"
            help = "Plot output file, format determined by extension (default: write to STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function main(args=ARGS)
    options = parse_arguments(args)

    ranks = Parquet2.readfile(options["posteriors"])
    conv_ranks = rank_table_to_dict(ranks)
    fig = plot_ranks(conv_ranks)

    if isnothing(options["outfile"])
        CairoMakie.activate!(; visible=true)
        display(fig)
    else
        save(options["outfile"], fig)
    end
end

if !isinteractive()
    main()
end