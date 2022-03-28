package b1gbb

import (
	"fmt"
)

// Progresser is an interface to tournament structures. They define the number of
// how a team that finishes a game in a certain rank progresses through a tournament.
type Tournament interface {
	ReadyGameIterator() GameIterator
	GameIterator() GameIterator
	PlayInGameIterator() GameIterator
	Propagate(game int, rank int, team int)
	Game(id int) (Game, bool)
	Clone() Tournament
}

// A Game defines an interface for querying teams in a matchup and the winner of
// the matchup.
type Game interface {
	Id() int
	NTeams() int
	Team(slot int) (int, bool)
	Rank(rank int) (int, bool)
	Ready() bool
	Completed() bool
	Clone() Game
}

// GameIterator is an interface to tournament structures. They define a means to
// iterate through Matchups.
type GameIterator interface {
	Next() bool
	Game() Game
}

type headToHeadMatchup struct {
	id        int
	teams     [2]int
	winnerIdx int
}

func (h headToHeadMatchup) Id() int {
	return h.id
}

func (h headToHeadMatchup) NTeams() int {
	return 2
}

func (h headToHeadMatchup) Team(slot int) (int, bool) {
	if slot < 0 || slot > 1 {
		return -1, false
	}
	return h.teams[slot], true
}

func (h headToHeadMatchup) Rank(rank int) (int, bool) {
	if rank < 0 || rank > 1 || h.winnerIdx < 0 {
		return -1, false
	}
	return h.teams[(h.winnerIdx+rank)%2], true
}

func (h headToHeadMatchup) Ready() bool {
	return h.teams[0] >= 0 && h.teams[1] >= 0
}

func (h headToHeadMatchup) Completed() bool {
	return h.winnerIdx >= 0
}

func (h headToHeadMatchup) Clone() Game {
	c := headToHeadMatchup{
		id:        h.id,
		teams:     h.teams,
		winnerIdx: h.winnerIdx,
	}
	return c
}

type singleEliminationGameIterator struct {
	matchups []headToHeadMatchup
	idx      int
}

func (i *singleEliminationGameIterator) Next() bool {
	i.idx++
	if i.idx >= len(i.matchups) {
		return false
	}
	return true
}

func (i *singleEliminationGameIterator) Game() Game {
	return i.matchups[i.idx]
}

type singleEliminationReadyGameIterator struct {
	matchups []headToHeadMatchup
	idx      int
}

func (i *singleEliminationReadyGameIterator) Next() bool {
	i.idx++
	for ; i.idx < len(i.matchups) && !i.matchups[i.idx].Ready(); i.idx++ {
	}
	if i.idx >= len(i.matchups) {
		return false
	}
	return true
}

func (i *singleEliminationReadyGameIterator) Game() Game {
	return i.matchups[i.idx]
}

type singleEliminationPlayInGameIterator struct {
	matchups    []headToHeadMatchup
	playInGames []int
	idx         int
}

func (i *singleEliminationPlayInGameIterator) Next() bool {
	i.idx++
	if i.idx >= len(i.playInGames) {
		return false
	}
	return true
}

func (i *singleEliminationPlayInGameIterator) Game() Game {
	return i.matchups[i.playInGames[i.idx]]
}

type singleEliminationTournament struct {
	matchups        []headToHeadMatchup
	gameProgression []int
	slotProgression []int
	playInGames     []int // indices into matchups
}

func (t *singleEliminationTournament) Propagate(game int, rank int, team int) {
	if game < 0 || game > len(t.gameProgression) {
		panic(fmt.Errorf("game number %d out of bounds [0,%d]", game, len(t.gameProgression)))
	}
	if rank < 0 || rank > 1 {
		panic(fmt.Errorf("rank %d out of bounds [0,1]", rank))
	}

	m := t.matchups[game]
	var winnerIdx int
	if team == m.teams[0] {
		winnerIdx = 0
	} else if team == m.teams[1] {
		winnerIdx = 1
	} else {
		panic(fmt.Errorf("team %d not playing in game %d between %v", team, game, m.teams))
	}
	m.winnerIdx = (winnerIdx + rank) % 2
	t.matchups[game] = m
	team = m.teams[m.winnerIdx]

	// The final game does not progress
	if game == len(t.gameProgression) {
		return
	}
	nextgame := t.gameProgression[game]
	nextslot := t.slotProgression[game]
	t.matchups[nextgame].teams[nextslot] = team

	return
}

func (t singleEliminationTournament) Game(id int) (Game, bool) {
	if id < 0 || id > len(t.matchups) {
		return nil, false
	}
	return t.matchups[id], true
}

func (t singleEliminationTournament) GameIterator() GameIterator {
	i := singleEliminationGameIterator{
		matchups: t.matchups,
		idx:      -1,
	}
	return &i
}

func (t singleEliminationTournament) ReadyGameIterator() GameIterator {
	i := singleEliminationReadyGameIterator{
		matchups: t.matchups,
		idx:      -1,
	}
	return &i
}

func (t singleEliminationTournament) PlayInGameIterator() GameIterator {
	i := singleEliminationPlayInGameIterator{
		matchups:    t.matchups,
		playInGames: t.playInGames,
		idx:         -1,
	}
	return &i
}

func (t singleEliminationTournament) Clone() Tournament {
	// clones partial--only the things that change in a simulation are copied
	matchups := make([]headToHeadMatchup, len(t.matchups))
	copy(matchups, t.matchups)
	c := singleEliminationTournament{
		matchups:        matchups,
		gameProgression: t.gameProgression,
		slotProgression: t.slotProgression,
		playInGames:     t.playInGames,
	}
	return &c
}

func NewTournament(s TournamentStructure) (Tournament, error) {
	// turn matchups into a list for faster processing
	// assumes all missing matchups are undefined team vs undefined team
	ngames := s.NTeams - 1
	matchups := make([]headToHeadMatchup, ngames)
	for i, m := range s.Matchups {
		// Seeds are 1-based, convert to 0-based
		matchups[i] = headToHeadMatchup{
			id:        i,
			teams:     [2]int{m[0] - 1, m[1] - 1},
			winnerIdx: -1,
		}
	}
	for i := len(s.Matchups); i < ngames; i++ {
		matchups[i] = headToHeadMatchup{
			id:        i,
			teams:     [2]int{-1, -1},
			winnerIdx: -1,
		}
	}

	// turn progressions into an index into the matchups list
	gameProgression := make([]int, ngames-1)
	slotProgression := make([]int, ngames-1)
	if len(s.Progression) != ngames-1 {
		return nil, fmt.Errorf("expected %d progressions, got %d", ngames-1, len(s.Progression))
	}
	for i, p := range s.Progression {
		// game numbers are 1-based, convert to 0-based
		// fmt.Printf("The winner of game %d progresses to game %d, slot %d\n", i+1, p[0], p[1])
		gameProgression[i] = p[0] - 1
		slotProgression[i] = p[1]
	}

	t := &singleEliminationTournament{
		matchups:        matchups,
		gameProgression: gameProgression,
		slotProgression: slotProgression,
	}

	// fill winners IN PLAY-IN ORDER!
	itr := t.ReadyGameIterator()
	for itr.Next() {
		game := itr.Game()
		// games and seeds are both 1-based, convert to 0-based
		if winner, ok := s.Winners[game.Id()+1]; ok {
			t.Propagate(game.Id(), 0, winner-1)
		}
	}

	// after propagating winners, find the play-in games
	playInGames := make([]int, 0, ngames)
	itr = t.GameIterator()
	for itr.Next() {
		game := itr.Game()
		if game.Completed() {
			continue
		}
		if game.Ready() {
			playInGames = append(playInGames, game.Id())
		}
	}

	t.playInGames = playInGames

	return t, nil
}
