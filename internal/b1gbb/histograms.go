package b1gbb

import (
	"fmt"
	"math"
	"sort"
)

type Histogram struct {
	ngames int
	nteams int
	wins   [][]int
	nsims  int
}

func NewHistogram(teams []string) *Histogram {
	nteams := len(teams)
	ngames := nteams - 1
	wins := make([][]int, ngames)
	for i := 0; i < ngames; i++ {
		wins[i] = make([]int, nteams)
	}
	h := Histogram{
		ngames: ngames,
		nteams: nteams,
		wins:   wins,
		nsims:  0,
	}
	return &h
}

func (h *Histogram) Accumulate(t *Tournament) {
	for game := 0; game < h.ngames; game++ {
		winner, _, ok := t.GetWinnerLoser(game)
		if !ok {
			continue // TODO: error out?
		}
		h.wins[game][winner]++
	}
	h.nsims++
}

type WinsDensity struct {
	ngames  int
	nteams  int
	density [][]float64
}

func (h *Histogram) Density() *WinsDensity {

	dens := make([][]float64, h.ngames)
	for game := 0; game < h.ngames; game++ {
		dens[game] = make([]float64, h.nteams)
		for winner := 0; winner < h.nteams; winner++ {
			dens[game][winner] = float64(h.wins[game][winner]) / float64(h.nsims)
		}
	}

	d := WinsDensity{
		ngames:  h.ngames,
		nteams:  h.nteams,
		density: dens,
	}
	return &d
}

type WinnerProb struct {
	Winner int
	Prob   float64
}

func (d *WinsDensity) GetBest() []WinnerProb {
	wp := make([]WinnerProb, d.ngames)
	for game := 0; game < d.ngames; game++ {
		for winner := 0; winner < d.nteams; winner++ {
			p := d.density[game][winner]
			if p > wp[game].Prob {
				wp[game].Winner = winner
				wp[game].Prob = p
			}
		}
	}
	return wp
}

type pickerTeam struct {
	picker int
	team   int
}

type PickerAccumulator struct {
	nPickers    int
	pickerNames []string
	picks       []Picks
	wins        []float64
	correct     []int
	points      []int

	winsByPickerByTeam map[pickerTeam]float64
	// firstGameWins is a team number to win count map for teams playing in first
	// games. This allows us to normalize teamWins.
	firstGameWins map[int]int
	nsims         int
}

func NewPickerAccumulator(picks map[string]Picks) *PickerAccumulator {
	npickers := len(picks)
	p := make([]Picks, npickers)
	i := 0
	pickers := make([]string, npickers)
	for picker, x := range picks {
		p[i] = x
		// convert from 1-indexed to 0-indexed
		for j := range p[i].Winners {
			p[i].Winners[j]--
		}
		pickers[i] = picker
		i++
	}
	return &PickerAccumulator{
		nPickers:           npickers,
		pickerNames:        pickers,
		picks:              p,
		wins:               make([]float64, npickers),
		correct:            make([]int, npickers),
		points:             make([]int, npickers),
		winsByPickerByTeam: make(map[pickerTeam]float64),
		firstGameWins:      make(map[int]int),
		nsims:              0,
	}
}

func (p *PickerAccumulator) Accumulate(t *Tournament) {
	thisTournamentTotals := make([]int, p.nPickers)
	for game := 0; game < t.nGames; game++ {
		winner, _, _ := t.GetWinnerLoser(game) // guaranteed to work
		for picker, pick := range p.picks {
			if pick.Winners[game] == winner {
				p.correct[picker]++
				p.points[picker] += pick.Points[game]
				thisTournamentTotals[picker] += pick.Points[game]
			}
		}
	}
	var firsts []int
	var best int
	for picker, points := range thisTournamentTotals {
		if points > best {
			best = points
			firsts = []int{picker}
		} else if points == best {
			firsts = append(firsts, picker)
		}
	}
	partialWins := 1. / float64(len(firsts))
	for _, picker := range firsts {
		p.wins[picker] += partialWins
		// picker wins, so accumulate excite-o-matic!
		for _, game := range t.FirstGames(nil) {
			// whoever wins this game is good for the picker, regardless of who the picker picked
			winner, loser, _ := t.GetWinnerLoser(game) // guaraneteed to work
			ptWinner := pickerTeam{picker: picker, team: winner}
			ptLoser := pickerTeam{picker: picker, team: loser}
			p.winsByPickerByTeam[ptWinner] += partialWins
			p.winsByPickerByTeam[ptLoser] += 0 // to force the element to exist in the map
		}
	}
	for _, game := range t.FirstGames(nil) {
		winner, loser, _ := t.GetWinnerLoser(game) // guaraneteed to work
		p.firstGameWins[winner]++
		p.firstGameWins[loser] += 0 // likewise
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
	ev := make([]ExpectedValues, p.nPickers)
	for picker := 0; picker < p.nPickers; picker++ {
		ev[picker] = ExpectedValues{
			Picker:  p.pickerNames[picker],
			Correct: float64(p.correct[picker]) / float64(p.nsims),
			Points:  float64(p.points[picker]) / float64(p.nsims),
			Wins:    float64(p.wins[picker]) / float64(p.nsims),
		}
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
	ev := make([]ExcitementValues, 0, p.nPickers)
	for picker := 0; picker < p.nPickers; picker++ {
		es := make(map[int]float64)
		pickerWins := p.wins[picker]
		// Victory is not possible, so root for whomever you want!
		if pickerWins == 0 {
			continue
		}

		for playInTeam, playInTeamWins := range p.firstGameWins {
			pt := pickerTeam{picker: picker, team: playInTeam}
			var pickerWinsGivenT float64
			var ok bool
			if pickerWinsGivenT, ok = p.winsByPickerByTeam[pt]; !ok {
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
			Picker:           p.pickerNames[picker],
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
	if i < n {
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
