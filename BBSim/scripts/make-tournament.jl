using ArgParse
using BBSim
using JSON3

function parse_arguments(args=ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "bracket"
            help = "Bracket definition JSON file"
            required = true
        "teams"
            help = "Team ranking JSON file"
            required = true
        "--outfile", "-o"
            help = "Path to output tournament definition (JSON format)"
    end

    return parse_args(args, s)
end

function make_game(g, team_dict)
    quadrant = getproperty(BBSim, Symbol(get(g, "quadrant", "None")))
    game = g["game"]
    teams = (get(team_dict, g["teams"][1], nothing), get(team_dict, g["teams"][2], nothing))
    winner_id = get(g, "winner", nothing)
    winner_team = get(team_dict, winner_id, nothing)
    value = get(g, "value", 0)

    return BBSim.Game(
        quadrant,
        game,
        teams,
        winner_team,
        value,
    )
end

function main(args=ARGS)
    options = parse_arguments(args)

    bracket = open(options["bracket"], "r") do io
        JSON3.read(io)
    end

    teams = open(options["teams"], "r") do io
        JSON3.read(io, Vector{BBSim.Team})
    end

    team_dict = Dict(string(BBSim.quadrant(team)) * string(BBSim.seed(team)) => team for team in filter(t -> !isnothing(BBSim.seed(t)), teams))
    games = make_game.(bracket, Ref(team_dict))

    tournament = BBSim.Tournament(games)
    
    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, JSON3.write(tournament))
        end
    else
        JSON3.pretty(JSON3.write(tournament))
    end
end

if !isinteractive()
    main(ARGS)
end