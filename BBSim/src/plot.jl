using CairoMakie

"""
    plot_ranks(ranks)

`ranks` is a dict with picker names as keys and a huge list of ranks that can be histogramed.
"""
function plot_ranks(ranks)
    fig = Figure(resolution = (800, 400 * length(ranks)))

    names = sort(keys(ranks))
    for (i,name) in enumerate(names)
        ax = Axis(fig[i,1], title=name)
        hist(ax, ranks[name],
            normalization = :pdf, 
            bar_labels = :values, 
            label_formatter = x -> round(x, digits=2), 
            label_size = 10,
            strokewidth = 0.5, 
            strokecolor = :black,
            xticks = 1:length(ranks),
        )
    end
    
    return fig

end