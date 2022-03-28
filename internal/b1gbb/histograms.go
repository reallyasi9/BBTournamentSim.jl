package b1gbb

import (
	"fmt"
	"math"
	"sort"
)

type gameTeam struct {
	game int
	team int
}

type Histogram struct {
	Wins  map[gameTeam]int
	NSims int
}

func NewHistogram() *Histogram {
	wins := make(map[gameTeam]int)
	h := Histogram{
		Wins:  wins,
		NSims: 0,
	}
	return &h
}

func (h *Histogram) Accumulate(t Tournament) {
	itr := t.GameIterator()
	for itr.Next() {
		game := itr.Game()
		if !game.Completed() {
			continue // TODO: error out?
		}
		winner, _ := game.Rank(0)
		gt := gameTeam{
			game: game.Id(),
			team: winner,
		}
		h.Wins[gt]++
	}
	h.NSims++
}

type WinsDensity struct {
	Density map[gameTeam]float64
}

func (h *Histogram) Density() *WinsDensity {
	dens := make(map[gameTeam]float64)
	for gt, wins := range h.Wins {
		dens[gt] = float64(wins) / float64(h.NSims)
	}

	d := WinsDensity{
		Density: dens,
	}
	return &d
}

type WinnerProb struct {
	Winner int
	Prob   float64
}

func (d *WinsDensity) GetBest() map[int]WinnerProb {
	wpmap := make(map[int]WinnerProb)
	for gt, p := range d.Density {
		wp := wpmap[gt.game]
		if p > wp.Prob {
			wp.Winner = gt.team
			wp.Prob = p
			wpmap[gt.game] = wp
		}
	}
	return wpmap
}

type pickerTeam struct {
	picker string
	team   int
}

type pickerStats struct {
	wins             float64
	correctPicks     int
	points           int
	winsByPlayInTeam map[int]float64
}

type PickerAccumulator struct {
	picks          map[string]Picks
	stats          map[string]pickerStats
	playInTeamWins map[int]int
	nsims          int
}

func NewPickerAccumulator(picks map[string]Picks) *PickerAccumulator {

	stats := make(map[string]pickerStats)
	for picker := range picks {
		stats[picker] = pickerStats{winsByPlayInTeam: make(map[int]float64)}
	}
	// games and seeds are 1-indexed in input, so correct that now
	fixedPicks := make(map[string]Picks)
	for picker, pick := range picks {
		pk := make(map[int]int)
		pt := make(map[int]int)
		for game := range pick.Winners {
			pk[game-1] = pick.Winners[game] - 1
			pt[game-1] = pick.Points[game]
		}
		fixedPicks[picker] = Picks{
			Points:  pt,
			Winners: pk,
		}
	}
	return &PickerAccumulator{
		picks:          fixedPicks,
		stats:          stats,
		playInTeamWins: make(map[int]int),
		nsims:          0,
	}
}

func (p *PickerAccumulator) Add(other *PickerAccumulator) *PickerAccumulator {
	for picker := range other.picks {
		if _, ok := p.picks[picker]; !ok {
			panic(fmt.Errorf("picker %s in other PickerAccumulator, but not this", picker))
		}
	}
	for picker := range p.picks {
		if _, ok := other.picks[picker]; !ok {
			panic(fmt.Errorf("picker %s in this PickerAccumulator, but not other", picker))
		}
	}
	for picker, stats := range other.stats {
		s := p.stats[picker]
		s.wins += stats.wins
		s.correctPicks += stats.correctPicks
		s.points += stats.points
		w := s.winsByPlayInTeam
		for team, wins := range stats.winsByPlayInTeam {
			w[team] += wins
		}
		s.winsByPlayInTeam = w
		p.stats[picker] = s
	}
	for team, wins := range other.playInTeamWins {
		p.playInTeamWins[team] += wins
	}
	p.nsims += other.nsims

	return p
}

func (p *PickerAccumulator) Accumulate(t Tournament) {
	thisTournamentTotals := make(map[string]int)
	itr := t.GameIterator()
	for itr.Next() {
		game := itr.Game()
		if !game.Completed() {
			continue
		}
		gameId := game.Id()
		winner, _ := game.Rank(0)
		for picker, pick := range p.picks {
			if pick.Winners[gameId] == winner {
				stats := p.stats[picker]
				stats.correctPicks++
				points := pick.Points[gameId]
				stats.points += points
				p.stats[picker] = stats
				thisTournamentTotals[picker] += points
			}
		}
	}
	var firsts []string
	var best int
	for picker, points := range thisTournamentTotals {
		if points > best {
			best = points
			firsts = []string{picker}
		} else if points == best {
			firsts = append(firsts, picker)
		}
	}
	partialWins := 1. / float64(len(firsts))
	for _, picker := range firsts {
		stats := p.stats[picker]
		stats.wins += partialWins
		// picker wins, so accumulate excite-o-matic!
		itr := t.PlayInGameIterator()
		for itr.Next() {
			game := itr.Game()
			// whoever wins this game is good for the picker, regardless of who the picker picked
			winner, _ := game.Rank(0)
			loser, _ := game.Rank(1)
			stats.winsByPlayInTeam[winner] += partialWins
			stats.winsByPlayInTeam[loser] += 0 // to force the element to exist in the map
		}
		p.stats[picker] = stats
	}
	itr = t.PlayInGameIterator()
	for itr.Next() {
		game := itr.Game()
		winner, _ := game.Rank(0)
		loser, _ := game.Rank(1)
		p.playInTeamWins[winner]++
		p.playInTeamWins[loser] += 0 // likewise
	}

	p.nsims++
}

type ExpectedValues struct {
	Picker  string
	Correct float64
	Points  float64
	Wins    float64
}

func (p *PickerAccumulator) ExpectedValues() []ExpectedValues {
	ev := make([]ExpectedValues, len(p.picks))
	i := 0
	for picker, stats := range p.stats {
		ev[i] = ExpectedValues{
			Picker:  picker,
			Correct: float64(stats.correctPicks) / float64(p.nsims),
			Points:  float64(stats.points) / float64(p.nsims),
			Wins:    stats.wins / float64(p.nsims),
		}
		i++
	}
	return ev
}

func (ev ExpectedValues) String() string {
	return fmt.Sprintf("{%s: <correct> = %f, <points> = %f, <championships> = %f}", ev.Picker, ev.Correct, ev.Points, ev.Wins)
}

type ExcitementValues struct {
	Picker           string
	ExcitementScores map[int]float64
}

func (p *PickerAccumulator) ExcitementValues() []ExcitementValues {
	ev := make([]ExcitementValues, 0, len(p.picks))
	for picker, stats := range p.stats {
		pickerWins := stats.wins
		// Victory is not possible, so root for whomever you want!
		if pickerWins == 0 {
			continue
		}

		es := make(map[int]float64)

		for playInTeam, playInTeamWins := range p.playInTeamWins {
			var pickerWinsGivenT float64
			var ok bool
			if pickerWinsGivenT, ok = stats.winsByPlayInTeam[playInTeam]; !ok {
				// If the picker wins, the team never wins, so do not root for this team
				es[playInTeam] = 0
				continue
			}
			if pickerWinsGivenT == pickerWins {
				// If the picker wins, the team always wins, so always root for this team
				es[playInTeam] = math.Inf(1)
				continue
			}
			// Wanted: probability of P winning given T wins
			// We have p(P&T) and p(T), so this is easy
			pTGivenP := float64(pickerWinsGivenT) / float64(playInTeamWins)
			// Normalize by the probability of P winning
			pP := float64(pickerWins) / float64(p.nsims)

			es[playInTeam] = pTGivenP / pP
		}
		ev = append(ev, ExcitementValues{
			Picker:           picker,
			ExcitementScores: es,
		})
	}
	return ev
}

func (ev *ExcitementValues) MostExciting(n int) ([]int, []float64) {
	nteams := len(ev.ExcitementScores)
	te := teamExcitement{
		teams:      make([]int, nteams),
		excitement: make([]float64, nteams),
	}
	i := 0
	for team, ex := range ev.ExcitementScores {
		te.teams[i] = team
		te.excitement[i] = ex
		i++
	}
	if i < n || n < 0 {
		n = i
	}
	sort.Sort(sort.Reverse(byExcitement(te)))
	return te.teams[:n], te.excitement[:n]
}

type teamExcitement struct {
	teams      []int
	excitement []float64
}

type byExcitement teamExcitement

func (a byExcitement) Len() int {
	return len(a.teams)
}
func (a byExcitement) Less(i, j int) bool {
	return a.excitement[i] < a.excitement[j]
}
func (a byExcitement) Swap(i, j int) {
	a.teams[i], a.teams[j] = a.teams[j], a.teams[i]
	a.excitement[i], a.excitement[j] = a.excitement[j], a.excitement[i]
}
