@kwdef struct Game
    quadrant::Quadrant = 0
    game::Int = 0
    teams::NTuple{2,Union{Team,Nothing}} = (nothing, nothing)
    winner::Union{Team,Nothing} = nothing
    value::Int = 0
end

StructTypes.StructType(::Type{Game}) = StructTypes.Struct()

function StructTypes.construct(::Type{Tuple{Union{Team,Nothing},Union{Team,Nothing}}}, x::Vector; kw...)
    length(x) == 2 || throw(ErrorException("cannot parse team pair"))
    t1 = isnothing(x[1]) ? nothing : Team(x[1])
    t2 = isnothing(x[2]) ? nothing : Team(x[2])
    return (t1, t2)
end

in_quadrant(g::Game, q::Quadrant) = g.quadrant == q
quadrant(g::Game) = g.quadrant
game_number(g::Game) = g.game
teams(g::Game) = g.teams
team(g::Game, i::Integer) = g.teams[i]
winner(g::Game) = g.winner
value(g::Game) = g.value
