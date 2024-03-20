function simulate(rng::AbstractRNG, model::AbstractModel, game::AbstractGame)
    w = winner(game)
    !isnothing(w) && return w
    return simulate_winner(rng, model, game)
end
simulate(model::AbstractModel, game::AbstractGame) = simulate(Random.GLOBAL_RNG, model, game)

function simulate(rng::AbstractRNG, model::AbstractModel, tournament::Tournament{T,P}) where {T,P}
    simulated_games = Dict{Int,AbstractGame{T,P}}()
    # for each game, if the teams are not set, look up the teams here
    simulated_teams = Dict{Int,Vector{Team{T}}}()
    for game in games(tournament)

    end
    winners = Dict(game_number(game) => simulate(rng, model, game) for game in games(tournament))

end

simulate(model::AbstractModel, tournament::Tournament) = simulate(Random.GLOBAL_RNG, model, tournament)