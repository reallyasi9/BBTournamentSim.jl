@kwdef struct GameSlot
    quadrant::Quadrant
    game::Int
    team::Int
    team_id::Int
end

abstract type AbstractGame end

struct Game <: AbstractGame
    quadrant::Quadrant
    game::Int
    probabilities::Dict{Int,Float64}
    next_game::AbstractGame
end

struct FinalFourGame <: AbstractGame
    game::Int
    probabilities::Dict{Int,Float64}
    next_game::ChampionshipGame
end

struct ChampionshipGame <: AbstractGame
    probabilities::Dict{Int,Float64}
end