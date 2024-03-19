abstract type AbstractTeam end

id(::AbstractTeam) = nothing
name(::AbstractTeam) = nothing
league(::AbstractTeam) = nothing
rating(::AbstractTeam) = nothing
seed(::AbstractTeam) = nothing
quadrant(::AbstractTeam) = nothing

@kwdef struct Team <: AbstractTeam
    id::Int
    name::String
    league::String
    rating::Float32
    seed::Union{Nothing, Int8} = nothing
    quadrant::Union{Nothing, Quadrant} = nothing
end

StructTypes.StructType(::Type{Team}) = StructTypes.Struct()

id(t::Team) = t.id
name(t::Team) = t.name
league(t::Team) = t.league
rating(t::Team) = t.rating
seed(t::Team) = t.seed
quadrant(t::Team) = t.quadrant

struct NullTeam <: AbstractTeam end