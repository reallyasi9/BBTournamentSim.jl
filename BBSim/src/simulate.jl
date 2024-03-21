function simulate(rng::AbstractRNG, model::AbstractModel, game::Game)
    w = winner(game)
    !isnothing(w) && return w
    return simulate_winner(rng, model, game)
end
simulate(model::AbstractModel, game::Game) = simulate(Random.GLOBAL_RNG, model, game)

function simulate(rng::AbstractRNG, model::AbstractModel, tournament::Tournament, n::Integer=1)
    n_games = length(tournament)
    simulated_winners = zeros(Team, n_games, n)
    for sim in 1:n
        t = deepcopy(tournament)
        for g in 1:n_games
            w = simulate(rng, model, game(t, g))
            propagate_winner(t, g, w)
            simulated_winners[g,sim] = w
        end
    end
    return simulated_winner
end

simulate(model::AbstractModel, tournament::Tournament) = simulate(Random.GLOBAL_RNG, model, tournament)