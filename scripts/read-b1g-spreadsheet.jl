using ArgParse
using BBTournamentSim
using JSON3
using XLSX

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "spreadsheet"
            help = "XLSX spreadsheet to parse"
            required = true
        "columns"
            help = "Column letters containing pickers to parse"
            required = true
            nargs = '+'
        "--sheet", "-s"
            help = "Sheet name containing picks"
            default = "Picks"
        "--outfile", "-o"
            help = "Path to output pseudo-picks file (JSON format)"
    end

    return parse_args(args, s)
end

function (@main)(args=ARGS)
    options = parse_arguments(args)

    pick_objs = Vector{Dict{String,Any}}()
    for col in options["columns"]
        data = String.(skipmissing(XLSX.readdata(options["spreadsheet"], options["sheet"], "$(col)1:$(col)75")))
        owner = data[1]
        picks = Vector{String}(undef,63)
        picks[1:8] .= Ref("NW") .* first.(split.(data[3:10]))
        picks[9:16] .= Ref("SW") .* first.(split.(data[11:18]))
        picks[17:24] .= Ref("NE") .* first.(split.(data[19:26]))
        picks[25:32] .= Ref("SE") .* first.(split.(data[27:34]))
        picks[33:36] .= Ref("NW") .* first.(split.(data[36:39]))
        picks[37:40] .= Ref("SW") .* first.(split.(data[40:43]))
        picks[41:44] .= Ref("NE") .* first.(split.(data[44:47]))
        picks[45:48] .= Ref("SE") .* first.(split.(data[48:51]))
        picks[49:50] .= Ref("NW") .* first.(split.(data[53:54]))
        picks[51:52] .= Ref("SW") .* first.(split.(data[55:56]))
        picks[53:54] .= Ref("NE") .* first.(split.(data[57:58]))
        picks[55:56] .= Ref("SE") .* first.(split.(data[59:60]))
        picks[57] = "NW" * first(split(data[62]))
        picks[58] = "SW" * first(split(data[63]))
        picks[59] = "NE" * first(split(data[64]))
        picks[60] = "SE" * first(split(data[65]))
        picks[61] = picks[56 + findfirst(==(data[67]), data[62:65])]
        picks[62] = picks[56 + findfirst(==(data[68]), data[62:65])]
        picks[63] = picks[56 + findfirst(==(data[70]), data[62:65])]
        
        push!(pick_objs, Dict("owner" => owner, "picks" => picks))
    end

    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, pick_objs)
        end
    else
        JSON3.pretty(pick_objs)
    end

    return 0
end
