package b1gbb

var links = [...]int{7, 11, 12, 15, 16, 19, 20, 21, 22, 23, 24, 25, -1}

type Tournament struct {
	teams    [14]int
	matchups [26]int
}

func CreateTournament() Tournament {
	ts := [14]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
	// B1G tournament structure
	ms := [26]int{11, 12, 10, 13, 7, 8, 4, -1, 6, 9, 5, -2, -3, 0, 3, -4, -5, 1, 2, -6, -7, -8, -9, -10, -11, -12}

	return Tournament{
		teams:    ts,
		matchups: ms,
	}
}

func WinnerTo(game int) int {
	return links[game]
}

func (t *Tournament) Teams(game int) (team1, team2 int) {
	matchup0 := game * 2
	team1 = t.matchups[matchup0]
	team2 = t.matchups[matchup0+1]
	return
}

func (t *Tournament) SetTeam(slot int, team int) {
	t.matchups[slot] = team
}
