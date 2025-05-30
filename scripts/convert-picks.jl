using ArgParse
using BBTournamentSim
using JSON3

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "picks"
            help = "Simple picks JSON file (as produced by download-cbs-picks.jl)"
            required = true
        "teams"
            help = "Team ranking JSON file (as produced by download-rpi.jl)"
            required = true
        "--outfile", "-o"
            help = "Path to output more complete picks file (JSON format)"
    end

    return parse_args(args, s)
end

function make_pick(p, team_dict)
    owner = get(p, "owner", "")
    tiebreaker = get(p, "tiebreaker", nothing)
    teams = [get(team_dict, t, nothing) for t in p["picks"]]

    return BBTournamentSim.Picks(
        owner,
        teams,
        tiebreaker,
    )
end

function main(args=ARGS)
    options = parse_arguments(args)

    picks = open(options["picks"], "r") do io
        JSON3.read(io)
    end

    teams = open(options["teams"], "r") do io
        JSON3.read(io, Vector{BBTournamentSim.Team})
    end

    team_dict = Dict(string(BBTournamentSim.quadrant(team)) * string(BBTournamentSim.seed(team)) => team for team in filter(t -> !isnothing(BBTournamentSim.seed(t)), teams))
    complete_picks = make_pick.(picks, Ref(team_dict))
    
    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, complete_picks)
        end
    else
        JSON3.pretty(complete_picks)
    end
end

if !isinteractive()
    main(ARGS)
end