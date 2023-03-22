using DataFrames
using DataFrames.PrettyTables
using YAML
using ArgParse

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

function parse_arguments(args)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "ranks"
            help = "Probability of rank in YAML format"
            required = true
        "matrix"
            help = "Probability of win by team win in YAML format"
            required = true
        "--outfile", "-o"
            help = "Output location of tables in HTML format (default: print to STDOUT)"
    end

    options = parse_args(args, s)

    return options
end

function main(args=ARGS)
    options = parse_arguments(args)

    ranks = YAML.load_file(options["ranks"])
    matrix = YAML.load_file(options["matrix"])

    n_pickers = length(ranks)
    ranks_df = DataFrame(Picker = String[])
    for i in 1:n_pickers
        col_name = ordinal_rank(i) * " place"
        ranks_df[!, col_name] = Float64[]
    end
    for (name, rank_row) in ranks
        push!(ranks_df, vcat([name], rank_row .* 100))
    end

    matrix_df = DataFrame(["Picker" => String[], "Winning Team" => String[], "Probability" => Float64[]])
    for (name, game_team_prob) in matrix
        for (_, team_prob) in game_team_prob
            for (team, prob) in team_prob
                push!(matrix_df, [name, team, (prob - ranks[name][1]) * 100])
            end
        end
    end
    matrix_df = unstack(matrix_df, "Picker", "Winning Team", "Probability") # todo: consider fill=0.?

    if isnothing(options["outfile"])
        io = stdout
    else
        io = open(options["outfile"], "w")
    end
    pretty_table(io, ranks_df; backend=Val(:html), tf=DataFrames.PrettyTables.tf_html_default, formatters=ft_printf("%d"))
    pretty_table(io, matrix_df; backend=Val(:html), tf=DataFrames.PrettyTables.tf_html_default, formatters=ft_printf("%+d"))
    close(io)
end

if !isinteractive()
    main()
end