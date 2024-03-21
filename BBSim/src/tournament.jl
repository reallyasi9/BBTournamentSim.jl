struct Tournament
    # who has won each game
    winners::Vector{Union{Nothing,Team}}
    # who is playing in each game
    teams::Array{Union{Nothing,Team},2}
    # how much is each game worth
    values::Vector{Int}
    
    function Tournament()
        winners = Vector{Union{Nothing,Team}}(nothing, 63)
        teams = Array{Union{Nothing,Team},2}(nothing, 2, 63)
        values = zeros(Int, 63)
        return new(winners, teams, values)
    end

    function Tournament(games::AbstractVector{Game})
        winners = Vector{Union{Nothing,Team}}(nothing, 63)
        ts = Array{Union{Nothing,Team},2}(nothing, 2, 63)
        values = vcat(
            repeat([1], 32),
            repeat([2], 16),
            repeat([4], 8),
            repeat([8], 4),
            repeat([16], 2),
            repeat([32], 1),
        )
        for game in games
            winners[game_number(game)] = winner(game)
            ts[:, game_number(game)] .= teams(game)
            values[game_number(game)] = value(game)
        end
        return new(winners, ts, values)
    end
end

function next_slot(t::Tournament, this_game::Integer)
    @boundscheck checkbounds(Bool, t.winners, this_game)
    this_game == 63 && return nothing
    slot = mod1(this_game, 2)
    this_game -= 1 # easier in 0-indexed numbers
    this_game < 32 && return (slot, 32 + this_game ÷ 2 + 1)
    this_game -= 32
    this_game < 16 && return (slot, 48 + this_game ÷ 2 + 1)
    this_game -= 16
    this_game < 8 && return (slot, 56 + this_game ÷ 2 + 1)
    this_game -= 8
    this_game < 4 && return (slot, 60 + this_game ÷ 2 + 1)
    return 63
end

function propagate_winner!(t::Tournament, game::Integer, team::Team)
    g = next_slot(t, game)
    isnothing(g) && return t
    t.teams[g] = team
    return t
end

function is_filled(t::Tournament, game::Integer)
    return !any(is_null, teams(t, game))
end

function is_done(t::Tournament, game::Integer)
    return is_filled(t, game) && !is_null(winner(t, game))
end

Base.size(t::Tournament) = size(t.winners)

function is_eliminated(t::Tournament, team::Team)
    for game in 1:length(t)
        if is_done(t, game) 
            if team in teams(t, game) && team != winner(t, game)
                return true
            end
        elseif team in teams(t, game)
            return false
        end
    end
    return false
end

winner(t::Tournament, game::Integer) = return t.winners[game]
teams(t::Tournament, game::Integer) = return @view(t.teams[:, game])
team(t::Tournament, game::Integer, slot::Integer) = return t.teams[slot, game]
