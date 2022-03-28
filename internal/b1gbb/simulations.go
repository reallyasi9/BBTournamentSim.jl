package b1gbb

import (
	"fmt"

	"golang.org/x/exp/rand"

	"gonum.org/v1/gonum/stat/distuv"
)

type GameSimulator interface {
	Simulate(Game) (rankings []int, probability float64)
}

type sagarinSimulator struct {
	model   distuv.Normal
	ratings []float64
}

func NewGameSimulator(src rand.Source, t1bias, stddev float64, ratings []float64) GameSimulator {
	model := distuv.Normal{
		Mu:    t1bias,
		Sigma: stddev,
		Src:   src,
	}
	return &sagarinSimulator{
		model:   model,
		ratings: ratings,
	}
}

func (s sagarinSimulator) Simulate(g Game) (rankings []int, probability float64) {
	if g.NTeams() != 2 {
		panic(fmt.Errorf("game %d requires exactly two teams, got %d", g.Id(), g.NTeams()))
	}
	if !g.Ready() {
		panic(fmt.Errorf("game %d is not ready to simulate", g.Id()))
	}
	if g.Completed() {
		winner, _ := g.Rank(0)
		loser, _ := g.Rank(1)
		rankings = []int{winner, loser}
		probability = 1
		return
	}
	team1, _ := g.Team(0)
	team2, _ := g.Team(1)
	rankings = []int{team1, team2}

	p1 := s.ratings[team1]
	p2 := s.ratings[team2]
	probability = s.model.CDF(p1 - p2)
	if s.model.Rand() < p1-p2 {
		return
	}
	probability = 1 - probability
	rankings[0], rankings[1] = rankings[1], rankings[0]
	return
}
