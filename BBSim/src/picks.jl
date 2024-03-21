struct Pick
    round::Int
    game::Int
    team::Team
end

round(p::Pick) = p.round
game(p::Pick) = p.game
team(p::Pick) = p.team


struct Picks
    picks::Vector{Pick}
    tiebreaker::Int
end

Base.size(p::Picks) = size(p.picks)
tiebreaker(p::Picks) = p.tiebreaker

function Base.iterate(p::Picks, state::Int = 1)
    state < 1 && return nothing
    state > length(p) && return nothing
    return (p.picks[state], state+1)
end


