@enum Quadrant begin
    NW = 1
    SW
    NE
    SE
end

@kwdef struct Team
    name::String
    kenpom::Float32
    seed::Union{Nothing, Int8} = nothing
    quadrant::Union{Nothing, Quadrant} = nothing
end

StructTypes.StructType(::Type{Team}) = StructTypes.Struct()