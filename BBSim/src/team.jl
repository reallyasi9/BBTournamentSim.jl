@kwdef struct Team
    id::Int
    name::String
    league::String
    rating::Float32
    seed::Union{Nothing, Int8} = nothing
    quadrant::Union{Nothing, Quadrant} = nothing
end

StructTypes.StructType(::Type{Team}) = StructTypes.Struct()