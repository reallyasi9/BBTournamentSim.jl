function simulate(rng::AbstractRNG, model::AbstractModel, game::Game)
    w = winner(game)
    !isnothing(w) && return w
    return simulate_winner(rng, model, teams(game))
end
simulate(model::AbstractModel, game::Game) = simulate(Random.GLOBAL_RNG, model, game)

function simulate(rng::AbstractRNG, model::AbstractModel, tournament::Tournament, n::Integer=1)
    n_games = length(tournament)
    simulated_winners = zeros(Int, n_games, n)
    @info "Simulating using threaded RNG" nsims=n Threads.nthreads()
    rngs = [Random.Xoshiro(rand(rng, UInt)) for _ in 1:Threads.nthreads()]
    Threads.@threads for sim in 1:n
        t = deepcopy(tournament)
        for g in 1:n_games
            if is_done(t, g)
                w = winner(t, g)
            else
                w = simulate_winner(rngs[Threads.threadid()], model, teams(t, g))
            end
            propagate_winner!(t, g, w) # just in case
            simulated_winners[g, sim] = id(w)
        end
    end
    return simulated_winners
end

simulate(model::AbstractModel, tournament::Tournament) = simulate(Random.GLOBAL_RNG, model, tournament)