function simulate(rng::AbstractRNG, model::AbstractModel, game::Game)
    w = winner(game)
    !isnothing(w) && return w
    return simulate_winner(rng, model, teams(game))
end
simulate(model::AbstractModel, game::Game) = simulate(Random.GLOBAL_RNG, model, game)

function simulate(rng::AbstractRNG, model::AbstractModel, tournament::Tournament, n::Integer=1)
    n_games = length(tournament)
    tasks_per_thread = 50
    chunk_size = max(1, n ÷ (tasks_per_thread * Threads.nthreads()))
    chunks = Iterators.partition(1:n, chunk_size)
    
    @info "Simulating using threaded RNG" nsims=n threads=Threads.nthreads()
    tasks = map(chunks) do chunk
        Threads.@spawn begin
            sim_wins = mapreduce(hcat, chunk) do _
                t = deepcopy(tournament)
                winners = map(1:n_games) do g
                    if is_done(t, g)
                        w = winner(t, g)
                    else
                        w = simulate_winner(rng, model, teams(t, g))
                    end
                    propagate_winner!(t, g, w)
                    return id(w)
                end
                return winners
            end
            return sim_wins
        end
    end

    simulated_winners = mapreduce(x -> fetch(x)::Matrix{Int}, hcat, tasks)

    return simulated_winners
end

simulate(model::AbstractModel, tournament::Tournament) = simulate(Random.default_rng(), model, tournament)