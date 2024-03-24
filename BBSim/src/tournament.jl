struct Tournament
    # who has won each game
    winners::Vector{Union{Nothing,Team}}
    # who is playing in each game
    teams::Vector{Union{Nothing,Team}}
    # how much is each game worth
    values::Vector{Int}
end

StructTypes.StructType(::Type{Tournament}) = StructTypes.Struct()

function Tournament()
    winners = Vector{Union{Nothing,Team}}(nothing, 63)
    teams = Vector{Union{Nothing,Team}}(nothing, 63*2)
    values = zeros(Int, 63)
    return Tournament(winners, teams, values)
end

function Tournament(games::AbstractVector{Game})
    winners = Vector{Union{Nothing,Team}}(nothing, 63)
    ts = Vector{Union{Nothing,Team}}(nothing, 63*2)
    values = vcat(
        repeat([1], 32),
        repeat([2], 16),
        repeat([4], 8),
        repeat([8], 4),
        repeat([16], 2),
        repeat([32], 1),
    )
    for game in games
        n = game_number(game)
        winners[n] = winner(game)
        start = (n-1)*2+1
        ts[start:start+1] .= teams(game)
        values[n] = value(game)
    end
    return Tournament(winners, ts, values)
end

function next_slot(t::Tournament, this_game::Integer)
    @boundscheck checkbounds(Bool, t.winners, this_game)
    this_game == 63 && return nothing
    slot = mod1(this_game, 2)
    this_game -= 1 # easier in 0-indexed numbers
    this_game < 32 && return (32 + this_game ÷ 2)*2 + slot
    this_game -= 32
    this_game < 16 && return (48 + this_game ÷ 2)*2 + slot
    this_game -= 16
    this_game < 8 && return (56 + this_game ÷ 2)*2 + slot
    this_game -= 8
    this_game < 4 && return (60 + this_game ÷ 2)*2 + slot
    return 62*2 + slot
end

function propagate_winner!(t::Tournament, game::Integer, team::Team)
    s = next_slot(t, game)
    isnothing(s) && return t
    t.teams[s] = team
    return t
end

function is_filled(t::Tournament, game::Integer)
    return !any(isnothing, teams(t, game))
end

function is_done(t::Tournament, game::Integer)
    return is_filled(t, game) && !isnothing(winner(t, game))
end

Base.size(t::Tournament) = size(t.winners)
Base.length(t::Tournament) = length(t.winners)

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


is_eliminated(::Tournament, team::Nothing) = false

winner(t::Tournament, game::Integer) = return t.winners[game]
teams(t::Tournament, game::Integer) = return @view(t.teams[(game-1)*2+1:(game-1)*2+2])
team(t::Tournament, game::Integer, slot::Integer) = return t.teams[(game-1)*2+slot]
values(t::Tournament) = return t.values
value(t::Tournament, game::Integer) = return t.values[game]