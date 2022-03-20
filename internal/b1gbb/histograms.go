package b1gbb

import (
	"fmt"
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
		winner, ok := t.GetWinner(game)
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

type PickerAccumulator struct {
	npickers int
	pickers  []string
	picks    []Picks
	wins     []int
	correct  []int
	points   []int
	teamWins []map[int]int
	nsims    int
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
		npickers: npickers,
		pickers:  pickers,
		picks:    p,
		wins:     make([]int, npickers),
		correct:  make([]int, npickers),
		points:   make([]int, npickers),
		teamWins: make([]map[int]int, npickers),
		nsims:    0,
	}
}

func (p *PickerAccumulator) Accumulate(t *Tournament) {
	totals := make([]int, p.npickers)
	for game := 0; game < t.nGames; game++ {
		winner, _ := t.GetWinner(game) // guaranteed to work
		for picker, pick := range p.picks {
			if pick.Winners[game] == winner {
				p.correct[picker]++
				p.points[picker] += pick.Points[game]
				totals[picker] += pick.Points[game]
			}
		}
	}
	var firsts []int
	var best int
	for picker, points := range totals {
		if points > best {
			best = points
			firsts = []int{picker}
		} else if points == best {
			firsts = append(firsts, picker)
		}
	}
	for _, picker := range firsts {
		p.wins[picker]++
		// picker wins, so accumulate excite-o-matic!
		if len(p.teamWins[picker]) == 0 {
			p.teamWins[picker] = make(map[int]int)
		}
		for _, game := range t.FirstGames(nil) {
			// whoever wins this game is good for the picker, regardless of who the picker picked
			winner, _ := t.GetWinner(game) // guaraneteed to work
			p.teamWins[picker][winner]++
		}
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
	ev := make([]ExpectedValues, p.npickers)
	for picker := 0; picker < p.npickers; picker++ {
		ev[picker] = ExpectedValues{
			Picker:  p.pickers[picker],
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
	ev := make([]ExcitementValues, 0, p.npickers)
	for picker := 0; picker < p.npickers; picker++ {
		es := make(map[int]float64)
		wins := float64(p.wins[picker])
		if wins == 0 {
			continue
		}
		for t, w := range p.teamWins[picker] {
			es[t] = float64(w) / wins
		}
		ev = append(ev, ExcitementValues{
			Picker:           p.pickers[picker],
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
