abstract type AbstractModel end

StructTypes.StructType(::Type{AbstractModel}) = StructTypes.AbstractType()

struct GaussianModel <: AbstractModel
    type::String
    dist::Normal
end

function GaussianModel(d::Dict{Symbol, Any})
    dist = Normal(get(d, "mean", 0.), get(d, "std", 1.))
    return GaussianModel("gaussian", dist)
end

StructTypes.StructType(::Type{GaussianModel}) = StructTypes.Struct()

function simulate_winner(rng::AbstractRNG, model::GaussianModel, game::Game)
    t1 = team(game, 1)
    t2 = team(game, 2)
    (isnothing(t1) || isnothing(t2)) && return nothing
    δ = rating(t1) - rating(t2)
    if rand(rng, model.dist) < δ
        return t1
    else
        return t2
    end
end

StructTypes.subtypekey(::Type{AbstractModel}) = :type
StructTypes.subtypes(::Type{AbstractModel}) = (gaussian=GaussianModel,)