using CairoMakie
using ArgParse
using YAML

function get_team_pairs(matrix)
    pair_count = Dict{Set{String}, Int}()
    for team_dict in values(matrix)
        team_names = collect(keys(team_dict))
        vals = collect(values(team_dict))

        mask = (vals .!= 1) .&& (vals .!= 0)
        team_names = team_names[mask]
        vals = vals[mask]

        m = repeat(vals, 1, length(vals))
        m += m'
        for i in 1:length(vals)
            for j in i+1:length(vals)
                if m[i, j] == 1
                    s = Set([team_names[i], team_names[j]])
                    pair_count[s] = get!(pair_count, s, 0) + 1
                end
            end
        end
    end
    return collect(keys(pair_count))
end

"""
    plot_matrix(ranks)

`ranks` is a dict with picker names as keys values are dicts with keys being team names and values being probabilities of coming in first place if that team wins its next game.
"""
function plot_matrix(matrix)
    pickers = collect(keys(matrix))
    sort!(pickers)
    n_pickers = length(pickers)

    pairs = get_team_pairs(matrix)
    teams = vcat([String[p...] for p in pairs]...)
    n_teams = length(teams)

    

    pickers = 
    n_ranks = length(ranks)
    fig = Figure(resolution = (800, 240 * n_ranks))
    names = sort(collect(keys(ranks)))

    xs = collect(1:n_ranks)
    for (i,name) in enumerate(names)
        ax = Axis(fig[i,1], title=name)
        pmap = StatsBase.proportionmap(ranks[name])
        ys = [get(pmap, x, 0.) for x in xs]
        max_y = maximum(ys)
        barplot!(ax, 
            xs,
            ys,
            bar_labels = :y, 
            label_formatter = x -> round(x, digits=2), 
            label_size = 12,
            strokewidth = 0.5, 
            strokecolor = :black,
            xticks = 1:length(ranks),
            flip_labels_at = max_y * .85,
            color_over_background = :black,
            color_over_bar = :white,
        )
    end

    return fig

end

function parse_arguments(args)
    s = ArgParseSettings
    @add_arg_table! s begin
        "matrix"
            help = "Probability of win matrix information in YAML format"
            required = true
        "--outfile", "-o"
            help = "Plot output file, format determined by extension (default: write to STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function main(args=ARGS)
    options = parse_arguments(args)

    matrix = YAML.load_file(options["matrix"])
    fig = plot_matrix(matrix)

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