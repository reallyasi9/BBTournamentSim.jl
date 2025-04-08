@kwdef struct Team
    id::Int = 0
    name::String = ""
    league::String = ""
    rating::Float32 = 0.0
    seed::Union{Nothing, Int8} = nothing
    quadrant::Union{Nothing, Quadrant} = nothing
end

Team(i::Integer) = Team(;id=i)
function Team(id::AbstractString)
    quad = getproperty(BBSim, Symbol(id[1:2]))
    seed = parse(Int8, id[3:end])
    idnum = (quad - 1) * 4 + seed
    return Team(;id=idnum, seed=seed, quadrant=quad)
end

StructTypes.StructType(::Type{Team}) = StructTypes.Struct()

id(t::Team) = t.id
name(t::Team) = t.name
league(t::Team) = t.league
rating(t::Team) = t.rating
seed(t::Team) = t.seed
quadrant(t::Team) = t.quadrant
is_null(t::Team) = t.id < 1
