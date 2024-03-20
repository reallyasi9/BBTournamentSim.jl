@enum Quadrant begin
    NW = 1
    SW
    NE
    SE
end

struct Pick{T}
    round::Int
    game::Int
    team::AbstractTeam{T}
end

round(p::Pick) = p.round
game(p::Pick) = p.game
team(p::Pick) = p.team


struct Picks{T,P}
    picks::Vector{Pick{T}}
    tiebreaker::P
end

Base.size(p::Picks) = size(p.picks)
tiebreaker(p::Picks) = p.tiebreaker

function Base.iterate(p::Picks, state::Int = 1)
    state < 1 && return nothing
    state > length(p) && return nothing
    return (p.picks[state], state+1)
end


