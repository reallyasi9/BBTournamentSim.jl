@kwdef struct Picks
    owner::String = ""
    # in tournament order
    picks::Vector{Union{Team, Nothing}} = Vector{Union{Team,Nothing}}(nothing, 63)
    tiebreaker::Union{Int,Nothing} = nothing
end

StructTypes.StructType(::Type{Picks}) = StructTypes.Struct()

Base.size(p::Picks) = size(p.picks)
Base.length(p::Picks) = length(p.picks)
Base.eltype(::Picks) = Union{Team,Nothing}
tiebreaker(p::Picks) = p.tiebreaker
owner(p::Picks) = p.owner
picks(p::Picks) = p.picks
pick(p::Picks, game::Integer) = picks(p::Picks)[game]

function Base.iterate(p::Picks, state::Int = 1)
    state < 1 && return nothing
    state > length(p) && return nothing
    return (p.picks[state], state+1)
end
