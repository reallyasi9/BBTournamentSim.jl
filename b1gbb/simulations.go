package b1gbb

import (
	"golang.org/x/exp/rand"

	"gonum.org/v1/gonum/stat/distuv"
)

type SagarinSimulator struct {
	model   distuv.Normal
	ratings []float64
}

func NewSagarinSimulator(src rand.Source, t1bias, stddev float64, ratings []float64) *SagarinSimulator {
	model := distuv.Normal{
		Mu:    t1bias,
		Sigma: stddev,
		Src:   src,
	}
	return &SagarinSimulator{
		model:   model,
		ratings: ratings,
	}
}

func (s *SagarinSimulator) ClonePartial(newsrc rand.Source) *SagarinSimulator {
	mu := s.model.Mu
	sigma := s.model.Sigma
	ratings := s.ratings
	if newsrc == nil {
		newsrc = rand.NewSource(s.model.Src.Uint64())
	}
	return NewSagarinSimulator(newsrc, mu, sigma, ratings)
}

func (s *SagarinSimulator) Simulate(team1, team2 int) (winner int, probability float64) {
	p1 := s.ratings[team1]
	p2 := s.ratings[team2]
	probability = s.model.CDF(p1 - p2)
	if s.model.Rand() < p1-p2 {
		winner = team1
		return
	}
	probability = 1 - probability
	winner = team2
	return
}
