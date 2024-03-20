@enum Quadrant begin
    NW = 1
    SW
    NE
    SE
end

abstract type AbstractGame{T,P<:Number} end

in_quadrant(::AbstractGame, ::Quadrant) = nothing
quadrants(::AbstractGame) = nothing
game_number(::AbstractGame) = nothing
teams(::AbstractGame) = nothing
team(::AbstractGame, ::Integer) = nothing
winner(::AbstractGame) = nothing
scores(::AbstractGame) = nothing
score(::AbstractGame, ::Integer) = nothing
next(::AbstractGame) = nothing
value(::AbstractGame{P}) = zero(P)
is_championship(::AbstractGame) = false
is_final_four(::AbstractGame) = false

struct Game{T,P} <: AbstractGame{T,P}
    quadrant::Quadrant
    game::Int
    teams::NTuple{2,Team{T}}
    winner::Ref{Team{T}}
    scores::NTuple{2,Int}
    next_game::AbstractGame{T,P}
    value::P
end

in_quadrant(g::Game, q::Quadrant) = g.quadrant == q
quadrants(g::Game) = Quadrant[g.quadrant]
game_number(g::Game) = g.game
teams(g::Game) = g.teams
team(g::Game, i::Integer) = g.teams[i]
winner(g::Game) = isassigned(g.winner) ? g.winner[] : nothing
scores(g::Game) = g.scores
score(g::Game, i::Integer) = g.scores[i]
next(g::Game) = g.next_game
value(g::Game) = g.value

struct FinalFourGame <: AbstractGame{T,P}
    quadrants::NTuple{2,Quadrant}
    game::Int
    teams::NTuple{2,AbstractTeam{T}}
    winner::Union{Nothing,AbstractTeam{T}}
    scores::NTuple{2,Int}
    next_game::ChampionshipGame
    value::P
end

in_quadrant(g::FinalFourGame, q::Quadrant) = q ∈ g.quadrants
quadrants(g::FinalFourGame) = Quadrant[g.quadrants...]
game_number(g::FinalFourGame) = g.game
teams(g::FinalFourGame) = g.teams
team(g::FinalFourGame, i::Integer) = g.teams[i]
winner(g::FinalFourGame) = g.winner
scores(g::FinalFourGame) = g.scores
score(g::FinalFourGame, ::Integer) = g.scores[i]
next(g::FinalFourGame) = g.next_game
value(g::FinalFourGame) = g.value
is_final_four(::FinalFourGame) = true

struct ChampionshipGame{T,P} <: AbstractGame{T,P}
    game::Int
    teams::NTuple{2,AbstractTeam{T}}
    winner::Union{Nothing,AbstractTeam{T}}
    scores::NTuple{2,Int}
    value::P
end

in_quadrant(::ChampionshipGame, ::Quadrant) = true
quadrants(::ChampionshipGame) = Quadrant[NW, SW, NE, SE]
game_number(g::ChampionshipGame) = g.game
teams(g::ChampionshipGame) = g.teams
team(g::ChampionshipGame, i::Integer) = g.teams[i]
winner(g::ChampionshipGame) = g.winner
scores(g::ChampionshipGame) = g.scores
score(g::ChampionshipGame, ::Integer) = g.scores[i]
value(g::ChampionshipGame) = g.value
is_championship(::ChampionshipGame) = true