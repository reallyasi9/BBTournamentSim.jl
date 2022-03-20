package b1gbb

import (
	"fmt"
)

type Tournament struct {
	nTeams      int
	nGames      int
	matchups    []int
	ready       []bool
	progression []int
	winners     map[int]int
	points      []int
	rules       []PointsRule
}

func NewTournament(s TournamentStructure) (*Tournament, error) {
	// turn matchups into a flat list for faster processing
	// assumes all missing matchups are undefined team vs undefined team
	ngames := s.NTeams - 1
	matchups := make([]int, ngames*2)
	ready := make([]bool, ngames)
	for i, m := range s.Matchups {
		matchups[i*2] = m[0] - 1
		matchups[i*2+1] = m[1] - 1
		if m[0] > 0 && m[1] > 0 { // both valid team IDs
			ready[i] = true
		}
	}

	// turn progressions into an index into the flat matchups list
	progression := make([]int, ngames-1)
	if len(s.Progression) != ngames-1 {
		return nil, fmt.Errorf("expected %d progressions, got %d", ngames-1, len(s.Progression))
	}
	for i, p := range s.Progression {
		progression[i] = p[0]*2 + p[1]
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
		nTeams:      s.NTeams,
		nGames:      s.NTeams - 1,
		matchups:    matchups,
		ready:       ready,
		progression: progression,
		winners:     make(map[int]int),
		points:      points,
		rules:       rules,
	}

	// fill winners
	for game, winner := range s.Winners {
		t.SetWinner(game, winner)
		t.ready[game] = false // already played
	}

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
		matchups:    matchups,
		ready:       t.ready,
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

func (t *Tournament) GetWinner(game int) (team int, ok bool) {
	team, ok = t.winners[game]
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
	return t.ready[game]
}
