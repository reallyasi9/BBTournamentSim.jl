@enum Quadrant begin
    NW = 1
    SW
    NE
    SE
end

abstract type AbstractGame end

in_quadrant(::AbstractGame, ::Quadrant) = nothing
quadrants(::AbstractGame) = nothing
game_number(::AbstractGame) = nothing
teams(::AbstractGame) = nothing
team(::AbstractGame, ::Integer) = nothing
next(::AbstractGame) = nothing
is_championship(::AbstractGame) = false
is_final_four(::AbstractGame) = false

struct Game <: AbstractGame
    quadrant::Quadrant
    game::Int
    teams::NTuple{2,AbstractTeam}
    next_game::AbstractGame
end

in_quadrant(g::Game, q::Quadrant) = g.quadrant == q
quadrants(g::Game) = Quadrant[g.quadrant]
game_number(g::Game) = g.game
teams(g::Game) = g.teams
team(g::Game, i::Integer) = g.teams[i]
next(g::Game) = g.next_game

struct FinalFourGame <: AbstractGame
    quadrants::NTuple{2,Quadrant}
    game::Int
    teams::NTuple{2,AbstractTeam}
    next_game::ChampionshipGame
end

in_quadrant(g::FinalFourGame, q::Quadrant) = q ∈ g.quadrants
quadrants(g::FinalFourGame) = Quadrant[g.quadrants...]
game_number(g::FinalFourGame) = g.game
teams(g::FinalFourGame) = g.teams
team(g::FinalFourGame, i::Integer) = g.teams[i]
next(g::FinalFourGame) = g.next_game
is_final_four(::FinalFourGame) = true

struct ChampionshipGame <: AbstractGame
    game::Int
    teams::NTuple{2,AbstractTeam}
end

in_quadrant(::ChampionshipGame, ::Quadrant) = true
quadrants(::ChampionshipGame) = Quadrant[NW, SW, NE, SE]
game_number(g::ChampionshipGame) = g.game
teams(g::ChampionshipGame) = g.teams
team(g::ChampionshipGame, i::Integer) = g.teams[i]
is_championship(::ChampionshipGame) = true