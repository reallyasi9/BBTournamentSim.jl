using CairoMakie
import StatsBase

"""
    plot_ranks(ranks)

`ranks` is a dict with picker names as keys and a huge list of ranks that can be histogramed.
"""
function plot_ranks(ranks)
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
        )
    end

    return fig

end