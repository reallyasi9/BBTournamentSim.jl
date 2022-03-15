package b1gbb

import "fmt"

type Tournament struct {
	nTeams      int
	nGames      int
	matchups    []int
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
	for i, m := range s.Matchups {
		matchups[i*2] = m[0] - 1
		matchups[i*2+1] = m[1] - 1
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
	rules := s.Points.Rules

	t := Tournament{
		nTeams:      s.NTeams,
		nGames:      s.NTeams - 1,
		matchups:    matchups,
		progression: progression,
		winners:     make(map[int]int),
		points:      points,
		rules:       rules,
	}

	// fill winners
	for game, winner := range s.Winners {
		t.SetWinner(game, winner)
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
