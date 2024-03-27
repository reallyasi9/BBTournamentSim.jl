abstract type AbstractModel end

StructTypes.StructType(::Type{AbstractModel}) = StructTypes.AbstractType()

struct GaussianModel <: AbstractModel
    type::String
    dist::Normal
end

function GaussianModel(d::Dict{Symbol,Any})
    dist = Normal(get(d, :mean, 0.), get(d, :std, 1.))
    return GaussianModel("gaussian", dist)
end

StructTypes.StructType(::Type{GaussianModel}) = StructTypes.DictType()

function simulate_winner(rng::AbstractRNG, model::GaussianModel, teams::AbstractVector{Union{Nothing,Team}})
    length(teams) != 2 && throw(ErrorException("GaussianModel can only predict outcomes for two teams"))
    t1 = teams[1]
    t2 = teams[2]
    (isnothing(t1) || isnothing(t2)) && return nothing
    Δ = rating(t1) - rating(t2)
    if rand(rng, model.dist) < Δ
        return t1
    else
        return t2
    end
end

StructTypes.subtypekey(::Type{AbstractModel}) = :type
StructTypes.subtypes(::Type{AbstractModel}) = (gaussian=GaussianModel,)