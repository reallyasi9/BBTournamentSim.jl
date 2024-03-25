using ArgParse
using JSON3

const LEAGUE_CHOICES = ("ncaaw", "ncaam", "b1gw", "b1gm")
const LEAGUE_GAMES = Dict(
    "ncaaw" => 63,
    "ncaam" => 63,
    "b1gw" => 13,
    "b1gm" => 13
)

"""
Standard scoring for NCAA brackets increases in powers of 2 per round such that the expected value of each game based on a coin flip picker is 1/2.

Standard scoring for B1G brackets is a choose-your-own-adventure where each game is assigned 1 to 13 points by the picker subject to the rules and no two games can be assigned the same point value and that the sum of point values assigned to a single round of the tournament add to no fewer than 5 points. The values presented here are typical given the game seeding and play-in rules.
"""
const LEAGUE_VALUES = Dict(
    "ncaaw" => vcat(
        repeat([1], 32), repeat([2], 16), repeat([4], 8), repeat([8], 4), repeat([16], 2), [32]
    ),
    "ncaam" => vcat(
        repeat([1], 32), repeat([2], 16), repeat([4], 8), repeat([8], 4), repeat([16], 2), [32]
    ),
    "b1gw" => [1, 4, 8, 7, 9, 6, 11, 12, 10, 13, 2, 3, 5],
    "b1gm" => [1, 4, 8, 7, 9, 6, 11, 12, 10, 13, 2, 3, 5],
)
const LEAGUE_SEED_ORDER = Dict{String, Vector{NTuple{2, Union{Nothing, Int}}}}(
    "ncaaw" => repeat([(1, 16), (8, 9), (5, 12), (4, 13), (6, 11), (3, 14), (7, 10), (2, 15)], 4),
    "ncaam" => repeat([(1, 16), (8, 9), (5, 12), (4, 13), (6, 11), (3, 14), (7, 10), (2, 15)], 4),
    "b1gw" => [(13, 12), (14, 11), (9, 8), (nothing, 5), (10, 7), (nothing, 6), (nothing, 1), (nothing, 4), (nothing, 2), (nothing, 3)],
    "b1gm" => [(13, 12), (14, 11), (9, 8), (nothing, 5), (10, 7), (nothing, 6), (nothing, 1), (nothing, 4), (nothing, 2), (nothing, 3)],
)
const LEAGUE_QUADRANTS = Dict{String, Vector{String}}(
    "ncaaw" => vcat(
        repeat(["NW"], 8), repeat(["SW"], 8), repeat(["NE"], 8), repeat(["SE"], 8), 
        repeat(["NW"], 4), repeat(["SW"], 4), repeat(["NE"], 4), repeat(["SE"], 4), 
        repeat(["NW"], 2), repeat(["SW"], 2), repeat(["NE"], 2), repeat(["SE"], 2), 
        ["NW", "SW", "NE", "SE"],
        repeat(["None"], 3),
    ),
    "ncaam" => vcat(
        repeat(["NW"], 8), repeat(["SW"], 8), repeat(["NE"], 8), repeat(["SE"], 8), 
        repeat(["NW"], 4), repeat(["SW"], 4), repeat(["NE"], 4), repeat(["SE"], 4), 
        repeat(["NW"], 2), repeat(["SW"], 2), repeat(["NE"], 2), repeat(["SE"], 2), 
        ["NW", "SW", "NE", "SE"],
        repeat(["None"], 3),
    ),
    "b1gw" => repeat(["None"], 13),
    "b1gm" => repeat(["None"], 13),
)

function parse_arguments(args=ARGS)
    
    s = ArgParseSettings()
    @add_arg_table! s begin
        "league"
            help = "League of bracket to generate (must be one of $(join(LEAGUE_CHOICES, ", ", ", or")))"
            range_tester = in(LEAGUE_CHOICES)
            required = true
        "--values"
            help = "Custom values of games (in tournament order)"
            arg_type = Int
            nargs = '+'
        "--outfile", "-o"
            help = "Path to output bracket shell file (JSON format)"
    end

    return parse_args(args, s)
end

function decorate_team_names(teams, quadrant)
    return map(x -> isnothing(x) ? string(x) : quadrant * string(x), teams)
end

function main(args=ARGS)
    options = parse_arguments(args)

    if options["league"] ∉ ("ncaaw", "ncaam")
        throw(ErrorException("only 'ncaaw' and 'ncaam' brackets are supported at this time"))
    end
    league = options["league"]

    if !isempty(options["values"]) && length(options["values"]) != LEAGUE_GAMES[league]
        throw(ErrorException("if supplied, 'values' must match number of games in league: expected $(LEAGUE_GAMES[league]), got $(length(options["values"]))"))
    end
    
    values = isempty(options["values"]) ? LEAGUE_VALUES[league] : options["values"]
    quadrants = LEAGUE_QUADRANTS[league]

    games = Vector{Dict{String,Any}}()
    for game in 1:LEAGUE_GAMES[league]
        quadrant = quadrants[game]
        teams = game > length(LEAGUE_SEED_ORDER[league]) ? (nothing, nothing) : decorate_team_names(LEAGUE_SEED_ORDER[league][game], quadrant)
        value = values[game]
        push!(games, Dict(
            "game" => game,
            "league" => league,
            "quadrant" => quadrant,
            "teams" => teams,
            "value" => value
        ))
    end
 
    if !isnothing(options["outfile"])
        open(options["outfile"], "w") do f
            JSON3.pretty(f, games)
        end
    else
        JSON3.pretty(games)
    end
end

if !isinteractive()
    main(ARGS)
end