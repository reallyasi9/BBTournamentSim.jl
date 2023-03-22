using CairoMakie
using ArgParse
using YAML

# matrix is a Dict of (picker => (game => winner)) => prob
# need to determine all possible winners of a given game
# return Dict of game => [winner]
function get_team_pairs(matrix)
    pairs = Dict{Int, Set{String}}()
    for game_winner_prob in values(matrix)
        for (game, winner_prob) in game_winner_prob
            winner_set = get!(pairs, game, Set{String}())
            union!(winner_set, keys(winner_prob))
        end
    end
    return pairs
end

percent_format(values) = map(values) do v
    "$(Int(round(v*100)))%"
end

"""
    plot_matrix(matrix, ranks)

`matrix` is a Dict of (picker => (game => winner)) => prob, and `ranks` is a dict of picker => [prob], where the vector [prob] is sorted by finishing rank (1 = first place, etc.).

If you cannot come in 1st place, you will not be plotted on the matrix.
"""
function plot_matrix(matrix, ranks)
    pickers = collect(keys(matrix))
    sort!(pickers)
    n_pickers = length(pickers)

    unordered_pairs = get_team_pairs(matrix)
    pairs = sort(unordered_pairs) # by index = game number
    n_games = length(pairs)

    fig = Figure(;
        resolution = (800, 40 * n_games * n_pickers),
        fonts = (regular = "DejaVu Sans"),
    )

    colors = cgrad(:tab10) # simple color scheme
    for (i,name) in enumerate(pickers)
        ax = Axis(
            fig[i,1];
            title=name,
            titlealign=:left,
            titlesize=24,
            xtrimspine = true,
            xtickformat = percent_format,
        )
        hidespines!(ax, :t, :l, :r)
        hideydecorations!(ax)

        game_winner_prob = matrix[name]
        p_win = ranks[name][1]

        left_xs = Float64[]
        right_xs = Float64[]
        ys = Int[]
        spans = Float64[] # for sorting
        left_labels = String[]
        right_labels = String[]

        y = 1
        for (game_number, teams) in pairs
            winner_prob = game_winner_prob[game_number]
            temp_xs = [get(winner_prob, t, 0.) for t in teams]
            l_x, r_x = extrema(temp_xs)
            l_t, r_t = teams
            if l_x == last(temp_xs)
                l_t, r_t = r_t, l_t
            end
            push!(left_xs, l_x)
            push!(right_xs, r_x)

            span = abs(l_x - r_x)
            push!(spans, span)
            push!(ys, y)
            y += 1

            push!(left_labels, "$l_t: $(Int(round((l_x - p_win)*100)))%")
            push!(right_labels, "$r_t: +$(Int(round((r_x - p_win)*100)))%")
        end

        p = sortperm(spans)
        invpermute!(ys, p)

        xmin = minimum(left_xs)
        xmax = maximum(right_xs)
        barplot!(
            ax,
            ys,
            left_xs,
            fillto = p_win,
            direction = :x,
            color = colors[2],
            bar_labels = left_labels,
            flip_labels_at = (xmin + p_win)/2,
            label_size = 16,
            color_over_background = :white,
            color_over_bar = colors[2],
        )
        barplot!(
            ax,
            ys,
            right_xs,
            fillto = p_win,
            direction = :x,
            color = colors[1],
            bar_labels = right_labels,
            flip_labels_at = (xmax + p_win)/2,
            label_size = 16,
            color_over_background = colors[1],
            color_over_bar = :white,
        )
        vlines!(
            ax,
            p_win,
            color = :black,
            linewidth = 4,
            linestyle = :dash,
        )
    end

    fig

end

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "ranks"
            help = "Probability of rank information in YAML format"
            required = true
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

    ranks = YAML.load_file(options["ranks"])
    matrix = YAML.load_file(options["matrix"])

    fig = plot_matrix(matrix, ranks)

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