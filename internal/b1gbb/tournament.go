package b1gbb

import (
	"fmt"
)

type Tournament struct {
	nTeams           int
	nGames           int
	teamNames        []string
	firstGames       []int
	completedAtStart []bool
	matchups         []int
	progression      []int
	winners          map[int]int
	points           []int
	rules            []PointsRule
}

func NewTournament(s TournamentStructure, teamsBySeed []string) (*Tournament, error) {
	// turn matchups into a flat list for faster processing
	// assumes all missing matchups are undefined team vs undefined team
	ngames := s.NTeams - 1
	matchups := make([]int, ngames*2)
	for i, m := range s.Matchups {
		// Seeds are 1-based, convert to 0-based
		tn1 := "(undefined)"
		if m[0] >= 0 {
			tn1 = teamsBySeed[m[0]-1]
		}
		tn2 := "(undefined)"
		if m[1] >= 0 {
			tn2 = teamsBySeed[m[1]-1]
		}
		fmt.Printf("Game %d: %s vs %s\n", i+1, tn1, tn2)
		matchups[i*2] = m[0] - 1
		matchups[i*2+1] = m[1] - 1
	}

	// turn progressions into an index into the flat matchups list
	progression := make([]int, ngames-1)
	if len(s.Progression) != ngames-1 {
		return nil, fmt.Errorf("expected %d progressions, got %d", ngames-1, len(s.Progression))
	}
	for i, p := range s.Progression {
		// game numbers are 1-based, convert to 0-based
		fmt.Printf("The winner of game %d progresses to game %d, slot %d\n", i+1, p[0], p[1])
		progression[i] = (p[0]-1)*2 + p[1]
	}

	// turn points structs into values and rules
	points := make([]int, ngames)
	if len(s.Points.Values) != ngames {
		return nil, fmt.Errorf("expected %d point values, got %d", ngames, len(s.Points.Values))
	}
	copy(points, s.Points.Values)

	rules := make([]PointsRule, len(s.Points.Rules))
	copy(rules, s.Points.Rules)

	t := Tournament{
		nTeams:           s.NTeams,
		nGames:           s.NTeams - 1,
		teamNames:        teamsBySeed,
		completedAtStart: make([]bool, s.NTeams-1),
		matchups:         matchups,
		progression:      progression,
		winners:          make(map[int]int),
		points:           points,
		rules:            rules,
	}

	// fill winners
	for game, winner := range s.Winners {
		// games and seeds are both 1-based, convert to 0-based
		fmt.Printf("Setting %s as the winner of game %d\n", teamsBySeed[winner-1], game)
		t.SetWinner(game-1, winner-1)
		t.completedAtStart[game-1] = true
	}

	// set first games
	firstGames := make([]int, 0, t.nGames)
	for game := 0; game < t.nGames; game++ {
		if t.IsReady(game) {
			t1, t2 := t.Teams(game)
			fmt.Printf("Game %d is ready to play: %s vs %s\n", game+1, t.teamNames[t1], t.teamNames[t2])
			firstGames = append(firstGames, game)
		}
	}
	t.firstGames = firstGames

	return &t, nil
}

func (t *Tournament) ClonePartial() *Tournament {
	matchups := make([]int, len(t.matchups))
	copy(matchups, t.matchups)
	winners := make(map[int]int)
	for key, val := range t.winners {
		winners[key] = val
	}
	return &Tournament{
		nTeams:      t.nTeams,
		nGames:      t.nGames,
		firstGames:  t.firstGames,
		matchups:    matchups,
		progression: t.progression,
		winners:     winners,
		points:      t.points,
		rules:       t.rules,
	}
}

func (t *Tournament) WinnerTo(game int) (int, bool) {
	if game >= t.nGames-1 || game < 0 {
		return -1, false
	}
	return t.progression[game], true
}

func (t *Tournament) Teams(game int) (team1, team2 int) {
	matchup0 := game * 2
	team1 = t.matchups[matchup0]
	team2 = t.matchups[matchup0+1]
	return
}

func (t *Tournament) SetWinner(game int, team int) {
	t.winners[game] = team
	if slot, ok := t.WinnerTo(game); ok {
		t.matchups[slot] = team
	}
}

func (t *Tournament) GetWinnerLoser(game int) (winner int, loser int, ok bool) {
	winner, ok = t.winners[game]
	w, loser := t.Teams(game)
	if w != winner {
		winner, loser = loser, winner
	}
	return
}

func (t *Tournament) ValidPoints(perm []int) bool {
	if len(perm) != len(t.points) {
		return false
	}
	for _, r := range t.rules {
		sum := 0
		for _, g := range r.Games {
			sum += t.points[perm[g]]
		}
		if sum < r.Minimum {
			return false
		}
	}
	return true
}

func (t *Tournament) RemainingMatchups() int {
	return len(t.matchups) - len(t.winners)
}

func (t *Tournament) IsReady(game int) bool {
	// valid teams in the matchup and no winner determined yet
	_, isWon := t.winners[game]
	if isWon {
		return false
	}
	return t.matchups[game*2] >= 0 && t.matchups[game*2+1] >= 0
}

func (t *Tournament) FirstGames(out []int) []int {
	if out == nil {
		out = make([]int, len(t.firstGames))
	}
	copy(out, t.firstGames)
	return out
}
